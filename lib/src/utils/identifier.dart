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

class Identifier<T extends Object> {
  final T value;

  const Identifier(this.value);

  static const defaultGroup = Identifier('DEFAULT_GROUP');

  static Identifier<Type> typeId(Type object) {
    final value = object;
    return Identifier<Type>(value);
  }

  /// Constructs a generic type string using the base type [T] and the provided
  /// [subTypes]. This is useful for dynamically creating type strings with
  /// multiple subtypes.
  ///
  /// Example:
  /// ```dart
  /// print(_constructGenericType<Map>(['String', 'int'])); // Map<String, int>
  /// print(_constructGenericType<Tuple3>(['A', 'B', 'C'])); // Tuple3<A, B, C>
  /// ```
  static Identifier<String> genericTypeId<T>(List<Identifier> subTypes) {
    final typeString = '$T';
    final n = typeString.indexOf('<');
    final base = typeString.substring(0, n == -1 ? typeString.length : n);
    final subTypeString = subTypes.join(', ');
    final value = '$base<$subTypeString>';
    return Identifier(value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Identifier<T>) return false;
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
