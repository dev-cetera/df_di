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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class Descriptor<T extends Object> {
  final T value;

  const Descriptor(this.value);

  static const defaultGroup = Descriptor('DEFAULT_GROUP');
  static const globalGroup = Descriptor('GLOBAL_GROUP');
  static const sessionGroup = Descriptor('SESSIONL_GROUP');
  static const prodGroup = Descriptor('PROD_GROUP');
  static const devGroup = Descriptor('DEV_GROUP');
  static const testGroup = Descriptor('TEST_GROUP');

  static Descriptor<Type> type(Type object) {
    final value = object;
    return Descriptor<Type>(value);
  }

  /// Constructs a generic type string context using the base type [T] and the
  /// provided [subTypes]. This is useful for dynamically creating type strings
  /// with multiple subtypes.
  ///
  /// Example:
  /// ```dart
  /// print(_constructGenericType<Map>(['String', 'int'])); // Map<String, int>
  /// print(_constructGenericType<Tuple3>(['A', 'B', 'C'])); // Tuple3<A, B, C>
  /// ```
  static Descriptor<String> genericType<T>(List<Descriptor> subTypes) {
    final typeString = '$T';
    final n = typeString.indexOf('<');
    final base = typeString.substring(0, n == -1 ? typeString.length : n);
    final subTypeString = subTypes.join(', ');
    final value = '$base<$subTypeString>';
    return Descriptor(value);
  }

  // Two Descriptors are equal if ther hashCodes are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Descriptor) return false;
    return other.hashCode == hashCode;
  }

  // Ensure [Descriptor] is identified by its String representation in Map keys.
  @override
  int get hashCode => value.toString().hashCode;

  @override
  String toString() => value.toString();
}
