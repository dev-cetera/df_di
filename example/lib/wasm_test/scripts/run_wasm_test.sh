#!/usr/bin/env bash
# Build the wasm_test harness for dart2wasm release (minified), serve it,
# load it in headless Chrome, and assert PASS based on the result marker the
# Flutter app writes into <title> and #__di_wasm_test_result__.
#
# Exit codes:
#   0  every scenario passed
#   1  one or more scenarios failed
#   2  build / serve / headless-chrome scaffolding failed
#
# Usage:
#   scripts/run_wasm_test.sh             # dart2wasm release (minified)
#   scripts/run_wasm_test.sh --dart2js   # dart2js release (minified)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${HERE}/.." && pwd)"
PORT="${PORT:-8765}"
TIMEOUT_MS="${TIMEOUT_MS:-30000}"
MODE="wasm"
if [[ "${1:-}" == "--dart2js" ]]; then
  MODE="dart2js"
fi

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [[ ! -x "${CHROME}" ]]; then
  echo "ERROR: Chrome not found at ${CHROME}" >&2
  exit 2
fi

cd "${APP_DIR}"

echo "==> Building wasm_test (${MODE} release)"
if [[ "${MODE}" == "wasm" ]]; then
  flutter build web --wasm --release 1>/dev/null
else
  flutter build web --release 1>/dev/null
fi
BUILD_DIR="${APP_DIR}/build/web"
if [[ ! -f "${BUILD_DIR}/index.html" ]]; then
  echo "ERROR: build output missing index.html" >&2
  exit 2
fi

# Verify dart2wasm minification is in effect: in release the wasm name section
# should be stripped (no readable Dart symbol names embedded). The .wasm file
# in release should be substantially smaller than a debug build and should not
# contain `package:df_di` in plaintext.
if [[ "${MODE}" == "wasm" ]]; then
  if grep -aq "package:df_di" "${BUILD_DIR}/main.dart.wasm" 2>/dev/null; then
    echo "WARNING: main.dart.wasm contains 'package:df_di' string — minification may not be active" >&2
  else
    echo "==> dart2wasm minification confirmed (no plaintext df_di package path in main.dart.wasm)"
  fi
fi

echo "==> Serving ${BUILD_DIR} on http://localhost:${PORT}"
python3 -m http.server "${PORT}" --directory "${BUILD_DIR}" 1>/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill ${SERVER_PID} 2>/dev/null || true' EXIT

# Wait for server to accept connections.
for _ in $(seq 1 50); do
  if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/" | grep -q "200"; then
    break
  fi
  sleep 0.1
done

PROFILE_DIR="$(mktemp -d -t wasm-test-profile-XXXXXX)"
trap 'kill ${SERVER_PID} 2>/dev/null || true; rm -rf "${PROFILE_DIR}"' EXIT

# Required Chrome flags for headless dart2wasm:
#   --enable-features=WebAssemblyTrapHandler is on by default; wasm GC is on.
#   --no-sandbox keeps things simple on CI.
#   --virtual-time-budget advances JS clock by N ms in headless mode.
#   Cross-Origin isolation headers aren't strictly required when serving from
#   the same origin in headless mode, but we keep CORS off to be safe.
echo "==> Loading harness in headless Chrome (timeout ${TIMEOUT_MS}ms)"
DUMP_FILE="$(mktemp -t wasm-test-dom-XXXXXX)"
trap 'kill ${SERVER_PID} 2>/dev/null || true; rm -rf "${PROFILE_DIR}" "${DUMP_FILE}"' EXIT

# Chrome --headless --dump-dom is known to occasionally hang after writing
# its dump on some Chrome/Mac builds. Wrap with a hard kill ceiling at
# 2× the virtual-time-budget so the script always terminates.
HARD_KILL_S=$(( (TIMEOUT_MS / 1000) * 2 + 10 ))
# `timeout` from coreutils (Homebrew); the bundled BSD `timeout` is not
# available on stock macOS, but the CI/dev box has gtimeout.
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout || true)"
if [[ -z "${TIMEOUT_BIN}" ]]; then
  echo "ERROR: install coreutils for the 'timeout' / 'gtimeout' binary" >&2
  exit 2
fi
set +e
"${TIMEOUT_BIN}" --kill-after=5s "${HARD_KILL_S}s" \
  "${CHROME}" \
    --headless \
    --disable-gpu \
    --no-sandbox \
    --user-data-dir="${PROFILE_DIR}" \
    --virtual-time-budget="${TIMEOUT_MS}" \
    --run-all-compositor-stages-before-draw \
    --dump-dom \
    "http://localhost:${PORT}/" \
    >"${DUMP_FILE}" 2>/dev/null
CHROME_EXIT=$?
set -e
# 124 is the timeout exit code; 137 is SIGKILL — both are expected if Chrome
# hangs post-dump. The DUMP_FILE is what we care about either way.
if [[ ${CHROME_EXIT} -ne 0 && ${CHROME_EXIT} -ne 124 && ${CHROME_EXIT} -ne 137 ]]; then
  echo "ERROR: Chrome failed with exit ${CHROME_EXIT}" >&2
  exit 2
fi

RESULT_LINE="$(grep -oE '__DI_WASM_TEST__:[^"<]*' "${DUMP_FILE}" | head -1 || true)"
if [[ -z "${RESULT_LINE}" ]]; then
  echo "FAIL: harness never published a result. First 60 lines of DOM dump:"
  head -60 "${DUMP_FILE}"
  exit 1
fi

echo "==> Result: ${RESULT_LINE}"
case "${RESULT_LINE}" in
  __DI_WASM_TEST__:PASS:*)
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
