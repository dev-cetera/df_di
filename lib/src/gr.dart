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

class Gr<T extends Object> {
  final T value;

  const Gr(this.value);

  static const defaultGroup = Gr('DEFAULT_GROUP');
  static const globalGroup = Gr('GLOBAL_GROUP');
  static const sessionGroup = Gr('SESSIONL_GROUP');
  static const prodGroup = Gr('PROD_GROUP');
  static const devGroup = Gr('DEV_GROUP');
  static const testGroup = Gr('TEST_GROUP');

  static const $1 = Gr('1');
  static const $2 = Gr('2');
  static const $3 = Gr('3');
  static const $4 = Gr('4');
  static const $5 = Gr('5');
  static const $6 = Gr('6');
  static const $7 = Gr('7');

  // Two Groups are equal if ther hashCodes are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Gr) return false;
    return other.hashCode == hashCode;
  }

  // Ensure [Groups] is identified by its String representation in Map keys.
  @override
  int get hashCode => value.toString().hashCode;

  @override
  String toString() => value.toString();
}

typedef Id = Gr;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class TypeGr extends Gr<String> {
  TypeGr(Object type) : super(type.toString());
}

typedef TypeId = TypeGr;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Constructs a `GenericTypeGr` based on the base type [T] and the optional
/// list of `subtypes`. If no subtypes are provided or the list is empty, the
/// method retains the original generic parameters from [T]. This is useful
/// for dynamically creating type strings with multiple subtypes.
///
/// Example:
/// ```dart
/// // With subtypes provided:
/// final id1 = GenericTypeGr<Map>([Gr('String'), Gr('int')]);
/// print(id1); // Map<String, int>
///
/// // Without subtypes:
/// final id2 = GenericTypeGr<Map>();
/// print(id2); // Map<String, String>
///
/// // Non-generic type:
/// final id3 = GenericTypeGr<int>();
/// print(id3); // int
/// ```
class GenericTypeGr<T extends Object> extends TypeGr {
  GenericTypeGr._(super.type);

  factory GenericTypeGr(List<Gr?>? subTypes) {
    final typeString = '$T';
    final n = typeString.indexOf('<');

    // If there is no generic type in the base type [T], return the type name directly.
    if (n == -1) {
      return GenericTypeGr._(typeString);
    }

    // If no subtypes are provided, retain the original generic parameters.
    if (subTypes == null || subTypes.isEmpty) {
      return GenericTypeGr._(typeString);
    }

    // Construct the generic type string using the provided subtypes.
    final base = typeString.substring(0, n);
    final subTypeString = subTypes.nonNulls.join(', ');
    final value = '$base<$subTypeString>';
    return GenericTypeGr._(value);
  }
}

typedef GenericTypeId<T extends Object> = GenericTypeGr<T>;
