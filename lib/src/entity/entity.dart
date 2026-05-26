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

import 'package:meta/meta.dart' show protected;

import 'reserved_entities.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Marker for entities whose equality is stricter than the base id-based
/// contract (e.g. [UniqueEntity]). [Entity.==] refuses to claim equality
/// from the loose side when `other` carries this marker, keeping `==`
/// symmetric — required for HashMap correctness. Subtypes must override
/// `==` themselves to enforce the stricter rule.
abstract interface class StrictEqualityEntity {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An entity is a uniquely identifiable object that serves as a container or
/// identifier for components in a Dependency Injection (DI) or
/// Entity-Component-System (ECS) framework.
///
/// ## Identity model (by design)
///
/// `Entity` is an **integer-identifier value type**, same model as Flutter's
/// `Key`. Two `Entity` instances with the same [id] are the same entity:
///
/// * [hashCode] is [id] by definition.
/// * `==` compares by [id] (and so, for [Entity] values, by [hashCode]).
/// * `Entity == nonEntity` returns true when `entity.id == objId(other)`.
///   This is intentional — an [Entity] is interchangeable with any object
///   that produces the same [objId]. It makes the [Entity.obj] factory and
///   `Map<Entity, ...>` lookups symmetric.
///
/// **Caveats this contract imposes on callers:**
///
/// * Anything that produces the same [id] *is* the same entity to this
///   package. For [TypeEntity] in particular, [id] is the type-string's
///   `hashCode` — see [TypeEntity] for the collision caveat and the
///   `--minify` caveat.
/// * Do not mix raw `int` / `String` keys with `Entity` keys in the same
///   `Map`/`Set`. The package itself never does this — `DIRegistry._state`
///   is `Map<Entity, ...>` end-to-end.
class Entity {
  /// Creates an integer [id] from the specified [object]. If the object
  /// is already an [int], it is returned as is. Otherwise, the object is
  /// converted to a string with spaces removed, then the [hashCode] is
  /// calculated and returned.
  @protected
  @pragma('vm:prefer-inline')
  static int objId(Object object) =>
      object is int ? object : object.toString().replaceAll(' ', '').hashCode;

  /// The value associated with this Entity instance.
  final int id;

  /// Creates a new instance of [Entity] identified by [id]. The [id] must be 0
  /// or greater.
  const Entity(this.id) : assert(id >= 0, 'Entity id must be 0 or greater!');

  @pragma('vm:prefer-inline')
  bool isDefault() => id == const DefaultEntity().id;

  /// Returns [other] if `this` is [DefaultEntity], otherwise returns `this`.
  @pragma('vm:prefer-inline')
  Entity preferOverDefault(Entity other) => isDefault() ? other : this;

  @pragma('vm:prefer-inline')
  bool isNotDefault() => !isDefault();

  /// Creates a new [Entity] with the given [id]. The [id] must be less than 0.
  ///
  /// Negative [id] values are reserved exclusively for internal use by the
  /// df_di package and [UniqueEntity]. They should not be used directly in
  /// your code.
  @protected
  const Entity.reserved(this.id)
      : assert(id < 0, 'Entity id must be negative!');

  /// Creates a new instance of [Entity] from the specified [object]. This
  /// effectively uses [objId] to convert the [object] to an [int] and then
  /// uses that as the [id] for the new [Entity] instance.
  factory Entity.obj(Object object) => Entity(objId(object));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // Reject `other` from the loose side so `==` stays symmetric — see
    // [StrictEqualityEntity].
    if (other is StrictEqualityEntity && this is! StrictEqualityEntity) {
      return false;
    }
    if (other is Entity) {
      return other.hashCode == hashCode;
    } else {
      return id == objId(other);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  int get hashCode => id;

  @override
  @pragma('vm:prefer-inline')
  String toString() => id.toString();
}
