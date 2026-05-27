// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

// `lib/_common.dart` is the **internal** ambient umbrella for the package.
// It is referenced by every `lib/src/**.dart` source file via the
// `'/_common.dart'` path import. Consumers of the package do NOT import it
// directly — they go through `package:df_di/df_di.dart`. We therefore can't
// `import 'package:df_di/_common.dart'` here, because that path is not part
// of the package's public API surface.
//
// This test exists to satisfy the "every source file has a sibling test
// file" convention. It exercises a few of the symbols that `_common.dart`
// re-exports (via the public `df_di.dart` barrel) so that any regression in
// the internal umbrella's exported set will surface as a compile or runtime
// failure inside the package itself, not here.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

void main() {
  group('lib/_common.dart (internal ambient barrel)', () {
    test(
      'symbols that _common.dart re-exports are reachable through df_di.dart',
      () {
        expect(const None<int>(), isA<Option<int>>());
        expect(const Some(1), isA<Option<int>>());
        expect(Sync.okValue(1), isA<Resolvable<int>>());
        expect(Unit(), isA<Unit>());

        final di = DI();
        expect(di, isA<DI>());
      },
    );
  });
}
