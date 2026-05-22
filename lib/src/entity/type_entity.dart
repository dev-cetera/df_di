//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

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
/// ## Identity model (by design)
///
/// `TypeEntity` inherits [Entity]'s integer-id identity model. Specifically:
///
/// * The [Entity.id] of a `TypeEntity` is `typeString.hashCode`. Two
///   `TypeEntity` instances with the same type-string are the same entity.
/// * Equality is by [Entity.id] alone — `_typeString` is *not* compared in
///   `==`. This is consistent with [Entity]'s contract and is what allows
///   `TypeEntity(MyService)` to be used as a const-friendly registry key.
///
/// **Caveats this contract imposes on callers:**
///
/// * **String-hash collisions.** Dart's `String.hashCode` is 32-bit. Two
///   distinct type-strings *can* collide on `hashCode`. For a single-app DI
///   registry with tens-to-low-hundreds of types, the collision probability
///   is negligible; for a registry meant to scale to thousands of distinct
///   types, this contract is not appropriate.
///
/// * **`Type.toString()` mangling under release.** When `baseType` is a
///   reified `Type`, this factory keys on `Type.toString()`. That string is
///   **not stable under `dart2js --minify`** (the default for
///   `flutter build web --release`) or under `dart compile wasm` —
///   distinct types can map to the same mangled name. Two compiler-mangled
///   names colliding means the corresponding registry slots merge silently.
///
///   Mitigations:
///   - Verify with a `dart2js --minify` / `wasm` CI build that the actual
///     registered types of your app do not collide post-minification.
///     The `example/wasm_test/` harness covers `until*`; extend it to cover
///     your app's specific type set.
///   - Or supply an explicit caller-controlled `Entity` via
///     `DependencyMetadata.preemptivetypeEntity` (constructed from a stable
///     string token under your control) so the registry key does not depend
///     on compiler output.
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
        final subTypeStrings = subTypes
            .map((st) => _getTypeString(st))
            .join(',');
        finalTypeString = '$initialCleanBaseTypeString<$subTypeStrings>';
      } else {
        final objectPlaceholder = _getTypeString(Object);
        final objectNullablePlaceholder = '$objectPlaceholder?';
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
