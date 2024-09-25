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

class DIKey<T extends Object> {
  final T value;
  late final String _key;
  late final int _hashCode;

  DIKey(this.value) {
    // Set during initialization for faster lookups.
    _key = _makeKey(value);
    _hashCode = _key.hashCode;
  }

  /// Constructs a `DIKey` representation by replacing occurrences of `Object`
  /// or `dynamic` in the `baseType` with corresponding values from `subTypes`.
  /// The replacements are applied sequentially based on their order in `subTypes`.
  ///
  /// If no `subTypes` are provided, the method returns the `baseType` as-is (after trimming spaces).
  ///
  /// Examples:
  /// ```dart
  /// // Example 1: Replacing multiple generic placeholders
  /// final type1 = DIKey.type(Map<Object, Object>, [String, int]);
  /// print(type1); // Output: Map<String,int>
  ///
  /// // Example 2: Replacing `dynamic`
  /// final type2 = DIKey.type('List<dynamic>', ['int']);
  /// print(type2); // Output: List<int>
  ///
  /// // Example 3: Handling non-generic types
  /// final type3 = DIKey.type(int);
  /// print(type3); // Output: int
  ///
  /// // Example 4: More complex generics
  /// final type4 = DIKey.type(Map<dynamic, List<Object>>, ['String', 'int']);
  /// print(type4); // Output: Map<String,List<int>>
  /// ```
  static DIKey<String> type(
    Object baseType, [
    List<Object> subTypes = const [],
  ]) {
    final objectStr = '$Object';
    final dynamicStr = '$dynamic';
    final cleanBaseType = baseType.toString().replaceAll(' ', '');
    var i = 0;
    // Traverse the processed type string and replace each occurrence of 'Object' or 'dynamic'.
    final buffer = StringBuffer();
    for (var n = 0; n < cleanBaseType.length; n++) {
      // Check for 'Object' or 'dynamic' starting at the current position.
      if (cleanBaseType.startsWith(objectStr, n) || cleanBaseType.startsWith(dynamicStr, n)) {
        // Replace with the next subtype from subTypes if available.
        if (i < subTypes.length) {
          buffer.write(subTypes[i].toString());
          i++;
        } else {
          // If no more subtypes are available, retain 'Object' or 'dynamic'.
          buffer.write(
            cleanBaseType.startsWith(objectStr, n) ? objectStr : dynamicStr,
          );
        }

        // Skip ahead over the matched word ('Object' or 'dynamic') dynamically.
        n += cleanBaseType.startsWith(objectStr, n) ? objectStr.length - 1 : dynamicStr.length - 1;
      } else {
        // Otherwise, just append the current character.
        buffer.write(cleanBaseType[n]);
      }
    }

    // Return the constructed type string wrapped in a DIKey object.
    return DIKey(buffer.toString());
  }

  static final defaultGroup = DIKey('DEFAULT_GROUP');
  static final globalGroup = DIKey('GLOBAL_GROUP');
  static final sessionGroup = DIKey('SESSION_USER_GROUP');
  static final userGroup = DIKey('USER_GROUP');
  static final sharedPreferences = DIKey('SHARED_PREFERENCES_GROUP');
  static final themeGroup = DIKey('THEME_GROUP');

  static final prodGroup = DIKey('PROD_GROUP');
  static final devGroup = DIKey('DEV_GROUP');
  static final testGroup = DIKey('TEST_GROUP');

  static final $0 = DIKey('0');
  static final $1 = DIKey('1');
  static final $2 = DIKey('2');
  static final $3 = DIKey('3');
  static final $4 = DIKey('4');
  static final $5 = DIKey('5');
  static final $6 = DIKey('6');
  static final $7 = DIKey('7');
  static final $8 = DIKey('7');
  static final $9 = DIKey('7');

  // Two Groups are equal if ther hashCodes are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is DIKey) {
      return other.hashCode == hashCode;
    } else {
      return _key == _makeKey(other);
    }
  }

  static String _makeKey(Object object) {
    return object.toString().replaceAll(' ', '');
  }

  @override
  int get hashCode => _hashCode;

  @override
  String toString() => _key;
}
