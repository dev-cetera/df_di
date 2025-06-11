//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: prefer_single_quotes

import 'entity.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Constructs a `Entity` representation by replacing occurrences of `Object`
/// or `dynamic` in the `baseType` with corresponding values from `subTypes`.
/// The replacements are applied sequentially based on their order in
/// `subTypes`.
///
/// If no `subTypes` are provided, the method returns the `baseType` as-is
/// (after trimming spaces).
///
/// ### Examples:
/// ```dart
/// // Example 1: Replacing multiple generic placeholders
/// final type1 = TypeEntity(Map<Object, Object>, [String, int]);
/// print(type1); // Output: Map<String,int>
///
/// // Example 2: Replacing `dynamic`
/// final type2 = TypeEntity('List<dynamic>', ['int']);
/// print(type2); // Output: List<int>
///
/// // Example 3: Handling non-generic types
/// final type3 = TypeEntity(int);
/// print(type3); // Output: int
///
/// // Example 4: More complex generics
/// final type4 = TypeEntity(Map<dynamic, List<Object>>, ['String', 'int']);
/// print(type4); // Output: Map<String,List<int>>
/// ```
final class TypeEntity extends Entity {
  //
  //
  //

  final String _typeString;

  //
  //
  //

  static String _getTypeString(dynamic object) {
    if (object is TypeEntity) {
      return object._typeString;
    }
    return object.toString().replaceAll(' ', '');
  }

  //
  //
  //

  TypeEntity._obj(String typeString)
      : _typeString = typeString,
        super(Entity.objId(typeString));

  //
  //
  //

  factory TypeEntity(Object baseType, [List<Object> subTypes = const []]) {
    final initialCleanBaseTypeString = _getTypeString(baseType);
    String finalTypeString;

    if (subTypes.isNotEmpty) {
      final isSimpleIdentifier = !initialCleanBaseTypeString.contains(
        RegExp(r'[<>,?]'),
      );
      if (isSimpleIdentifier) {
        final subTypeStrings =
            subTypes.map((st) => _getTypeString(st)).join(',');
        finalTypeString = '$initialCleanBaseTypeString<$subTypeStrings>';
      } else {
        final objectPlaceholder = _getTypeString(Object);
        final objectNullablePlaceholder = "$objectPlaceholder?";
        final dynamicPlaceholder = _getTypeString(dynamic);

        var subTypeIndex = 0;
        final buffer = StringBuffer();
        var n = 0;
        while (n < initialCleanBaseTypeString.length) {
          var matched = false;
          if (initialCleanBaseTypeString.startsWith(
            objectNullablePlaceholder,
            n,
          )) {
            if (subTypeIndex < subTypes.length) {
              buffer.write(_getTypeString(subTypes[subTypeIndex]));
              subTypeIndex++;
            } else {
              buffer.write(objectNullablePlaceholder);
            }
            n += objectNullablePlaceholder.length;
            matched = true;
          } else if (initialCleanBaseTypeString.startsWith(
            objectPlaceholder,
            n,
          )) {
            if (subTypeIndex < subTypes.length) {
              buffer.write(_getTypeString(subTypes[subTypeIndex]));
              subTypeIndex++;
            } else {
              buffer.write(objectPlaceholder);
            }
            n += objectPlaceholder.length;
            matched = true;
          } else if (initialCleanBaseTypeString.startsWith(
            dynamicPlaceholder,
            n,
          )) {
            if (subTypeIndex < subTypes.length) {
              buffer.write(_getTypeString(subTypes[subTypeIndex]));
              subTypeIndex++;
            } else {
              buffer.write(dynamicPlaceholder);
            }
            n += dynamicPlaceholder.length;
            matched = true;
          }
          if (!matched) {
            buffer.write(initialCleanBaseTypeString[n]);
            n++;
          }
        }
        finalTypeString = buffer.toString();
      }
    } else {
      finalTypeString = initialCleanBaseTypeString;
    }
    return TypeEntity._obj(finalTypeString);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class GenericEntity<T> extends TypeEntity {
  //
  //
  //

  GenericEntity._(super.typeString) : super._obj();

  //
  //
  //

  factory GenericEntity() {
    // This will use the TypeEntity factory to construct the canonical string for T
    final typeEntityInstanceForT = TypeEntity(T);
    return GenericEntity._(typeEntityInstanceForT._typeString);
  }
}
