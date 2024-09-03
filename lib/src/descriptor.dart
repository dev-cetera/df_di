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

class Id<T extends Object> {
  final T value;

  const Id(this.value);

  static const defaultGroup = Id('DEFAULT_GROUP');
  static const globalGroup = Id('GLOBAL_GROUP');
  static const sessionGroup = Id('SESSIONL_GROUP');
  static const prodGroup = Id('PROD_GROUP');
  static const devGroup = Id('DEV_GROUP');
  static const testGroup = Id('TEST_GROUP');

  // Two Groups are equal if ther hashCodes are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Id) return false;
    return other.hashCode == hashCode;
  }

  // Ensure [Groups] is identified by its String representation in Map keys.
  @override
  int get hashCode => value.toString().hashCode;

  @override
  String toString() => value.toString();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class TypeId extends Id<String> {
  TypeId(Object type) : super(type.toString());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Constructs a generic type string context using the base type [T] and the
/// provided [subTypes]. This is useful for dynamically creating type strings
/// with multiple subtypes.
///
/// Example:
/// ```dart
/// print(_constructGenericType<Map>(['String', 'int'])); // Map<String, int>
/// print(_constructGenericType<Tuple3>(['A', 'B', 'C'])); // Tuple3<A, B, C>
/// ```
class GenericTypeId<T> extends TypeId {
  GenericTypeId._(super.type);
  factory GenericTypeId(List<Id> subTypes) {
    final typeString = '$T';
    final n = typeString.indexOf('<');
    final base = typeString.substring(0, n == -1 ? typeString.length : n);
    final subTypeString = subTypes.join(', ');
    final value = '$base<$subTypeString>';
    return GenericTypeId._(value);
  }
}
