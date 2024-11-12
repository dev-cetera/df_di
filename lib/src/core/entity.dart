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

class Entity<T extends Object> {
  /// A predefined entity recommended to use as the default group entity for
  /// dependencies. This entity can be utilized when no specific group is
  /// defined, allowing for a fallback option that simplifies dependency
  /// retrieval and management in the DI container.
  static final defaultGroup = Entity('DEFAULT_GROUP');

  /// A predefined entity recommended to use as the global group entity for
  /// dependencies. Use This entity for dependencies that need to be accessible
  /// throughout the entire application, regardless of the current scope or
  /// context. This is ideal for singleton services or configurations that
  /// should remain consistent across all parts of the application.
  static final globalGroup = Entity('GLOBAL_GROUP');

  /// A predefined entity recommended to use as the session group entity for
  /// dependencies. This entity is intended for dependencies that should be
  /// specific to the current user's session, ensuring that the state
  /// and behavior are isolated from other sessions. It is useful for
  /// services that handle user-specific data or contexts.
  static final sessionGroup = Entity('SESSION_GROUP');

  /// A predefined entity recommended to use as the user group entity for
  /// dependencies. This entity is designed for managing dependencies
  /// that are user-specific, such as user preferences, settings,
  /// or any other data that varies from user to user. It helps
  /// organize services related to user management.
  static final userGroup = Entity('USER_GROUP');

  /// A predefined entity recommended to use as the theme group entity for
  /// dependencies. This entity is suitable for managing theme-related
  /// services or configurations that control the application's
  /// visual appearance. It allows for easy access and modification
  /// of UI themes, such as light or dark modes.
  static final themeGroup = Entity('THEME_GROUP');

  /// A predefined entity recommended to use as the production group entity for
  /// dependencies. This entity is intended for services that are specific
  /// to the production environment, ensuring that production-only
  /// configurations or resources are appropriately managed and
  /// distinguished from other environments (like development or testing).
  static final prodGroup = Entity('PROD_GROUP');

  /// A predefined entity recommended to use as the development group entity for
  /// dependencies. This entity is useful for managing services that are
  /// intended for development purposes, such as debugging tools,
  /// mock services, or any other resources that assist during the
  /// development process. It helps isolate development-specific
  /// functionality from production code.
  static final devGroup = Entity('DEV_GROUP');

  /// A predefined entity recommended to use as the test group entity for
  /// dependencies. This entity is designated for managing services that
  /// are utilized during testing, allowing for easy access to mock
  /// dependencies, test doubles, or any configurations necessary
  /// for unit tests and integration tests. It ensures that test
  /// services do not interfere with the application's production or
  /// development dependencies.
  static final testGroup = Entity('TEST_GROUP');

  /// Creates a key string from the given [object] with all spaces removed.
  static String _makeKey(Object object) => object.toString().replaceAll(' ', '');

  /// The value associated with this Entity instance.
  final T value;

  /// The key derived from the [value], uniquely identifying this instance.
  late final String _key;

  /// The hash code for this instance, derived from [_key].
  late final int _hashCode;

  /// Creates a new instance of [Entity] with the specified [value].
  Entity(this.value) {
    // Initialize the key and hash code during construction for efficiencient
    // lookups.
    _key = _makeKey(value);
    _hashCode = _key.hashCode;
  }

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
  /// final type1 = Entity.type(Map<Object, Object>, [String, int]);
  /// print(type1); // Output: Map<String,int>
  ///
  /// // Example 2: Replacing `dynamic`
  /// final type2 = Entity.type('List<dynamic>', ['int']);
  /// print(type2); // Output: List<int>
  ///
  /// // Example 3: Handling non-generic types
  /// final type3 = Entity.type(int);
  /// print(type3); // Output: int
  ///
  /// // Example 4: More complex generics
  /// final type4 = Entity.type(Map<dynamic, List<Object>>, ['String', 'int']);
  /// print(type4); // Output: Map<String,List<int>>
  /// ```
  static Entity<String> type(
    Object baseType, [
    List<Object> subTypes = const [],
  ]) {
    final objectStr = '$Object';
    final dynamicStr = '$dynamic';
    final cleanBaseType = baseType.toString().replaceAll(' ', '');
    var subTypeIndex = 0;

    // Build a new type string by replacing 'Object' or 'dynamic' with subTypes.
    final buffer = StringBuffer();
    for (var n = 0; n < cleanBaseType.length; n++) {
      // Check for 'Object' or 'dynamic' at the current position.
      if (cleanBaseType.startsWith(objectStr, n) || cleanBaseType.startsWith(dynamicStr, n)) {
        // Replace with the next subtype from subTypes if available.
        if (subTypeIndex < subTypes.length) {
          buffer.write(subTypes[subTypeIndex].toString());
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
    return Entity(buffer.toString());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Entity) {
      return other.hashCode == hashCode;
    } else {
      return _key == _makeKey(other);
    }
  }

  @override
  int get hashCode => _hashCode;

  @override
  String toString() => _key;
}
