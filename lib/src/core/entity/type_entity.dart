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

import 'entity.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class TypeEntity extends Entity {
  final String _typeString;

  static String _getTypeString(Object object) =>
      object is TypeEntity ? object._typeString : object.toString();

  TypeEntity._obj(Object object, this._typeString) : super(Entity.objId(object));

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
  factory TypeEntity(
    Object baseType, [
    List<Object> subTypes = const [],
  ]) {
    final objectStr = '$Object';
    final dynamicStr = '$dynamic';
    final cleanBaseType = _getTypeString(baseType).replaceAll(' ', '');
    var subTypeIndex = 0;

    // Build a new type string by replacing 'Object' or 'dynamic' with subTypes.
    final buffer = StringBuffer();
    for (var n = 0; n < cleanBaseType.length; n++) {
      // Check for 'Object' or 'dynamic' at the current position.
      if (cleanBaseType.startsWith(objectStr, n) || cleanBaseType.startsWith(dynamicStr, n)) {
        // Replace with the next subtype from subTypes if available.
        if (subTypeIndex < subTypes.length) {
          buffer.write(_getTypeString(subTypes[subTypeIndex]));
          subTypeIndex++;
        } else {
          // Retain 'Object' or 'dynamic' if no subtypes are left.
          buffer.write(
            cleanBaseType.startsWith(objectStr, n) ? objectStr : dynamicStr,
          );
        }

        // Skip ahead over the matched word.
        n += cleanBaseType.startsWith(objectStr, n) ? objectStr.length - 1 : dynamicStr.length - 1;
      } else {
        // Append the current character if it's not part of 'Object' or 'dynamic'.
        buffer.write(cleanBaseType[n]);
      }
    }

    // Return the constructed type string wrapped in a Entity object.
    final buffer1 = buffer.toString();
    return TypeEntity._obj(
      buffer1,
      buffer1,
    );
  }
}
