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

  static const $1 = Id('1');
  static const $2 = Id('2');
  static const $3 = Id('3');
  static const $4 = Id('4');
  static const $5 = Id('5');
  static const $6 = Id('6');
  static const $7 = Id('7');

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

/// Constructs a `GenericTypeId` based on the base type [T] and the optional
/// list of `subtypes`. If no subtypes are provided or the list is empty, the
/// method retains the original generic parameters from [T]. This is useful
/// for dynamically creating type strings with multiple subtypes.
///
/// Example:
/// ```dart
/// // With subtypes provided:
/// final id1 = GenericTypeId<Map>([Id('String'), Id('int')]);
/// print(id1); // Map<String, int>
///
/// // Without subtypes:
/// final id2 = GenericTypeId<Map>();
/// print(id2); // Map<String, String>
///
/// // Non-generic type:
/// final id3 = GenericTypeId<int>();
/// print(id3); // int
/// ```
class GenericTypeId<T> extends TypeId {
  GenericTypeId._(super.type);

  factory GenericTypeId(List<Id?>? subTypes) {
    final typeString = '$T';
    final n = typeString.indexOf('<');

    // If there is no generic type in the base type [T], return the type name directly.
    if (n == -1) {
      return GenericTypeId._(typeString);
    }

    // If no subtypes are provided, retain the original generic parameters.
    if (subTypes == null || subTypes.isEmpty) {
      return GenericTypeId._(typeString);
    }

    // Construct the generic type string using the provided subtypes.
    final base = typeString.substring(0, n);
    final subTypeString = subTypes.nonNulls.join(', ');
    final value = '$base<$subTypeString>';
    return GenericTypeId._(value);
  }
}
