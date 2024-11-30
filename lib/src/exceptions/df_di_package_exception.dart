//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

/// An exception only thrown by the `df_di` package.
abstract base class DFDIPackageException implements Exception {
  final String condition;
  final String reason;
  final List<String> options;

  DFDIPackageException({
    required this.condition,
    this.reason = '',
    this.options = const [],
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('$runtimeType ($DFDIPackageException):');
    buffer.writeln('Condition: $condition');
    if (reason.isNotEmpty) {
      buffer.writeln('Reason: $reason');
    }

    if (options.isNotEmpty) {
      buffer.writeln('Consider trying the following option(s):');
      for (final option in options) {
        buffer.writeln('- $option');
      }
    }

    return buffer.toString();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class GeneralException extends DFDIPackageException {
  GeneralException(String condition)
      : super(
          condition: condition,
        );
}
