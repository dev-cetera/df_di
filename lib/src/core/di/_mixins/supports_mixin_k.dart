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

// ignore_for_file: invalid_use_of_protected_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsMixinK on DIBase {
  @protected
  // Result<Option<Resolvable<Object>>> getK(
  //   Entity typeEntity, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final g = groupEntity.isDefault() ? focusGroup : groupEntity;
  //   final dep = _getDependencyK(
  //     typeEntity,
  //     groupEntity: g,
  //     traverse: traverse,
  //   );
  //   if (dep.isErr) {
  //     return dep.err;
  //   }
  //   if (dep.unwrap().isNone) {
  //     return const Ok(None<Object>());
  //   }
  //   final value = dep.unwrap().unwrap().value;
  //   switch (value) {
  //     case Future<Object> futureValue:
  //       return Ok(
  //         Some(() async {
  //           final value = await futureValue;
  //           _registerDependencyK(
  //             dependency: Dependency(
  //               value,
  //               metadata: dep.unwrap().unwrap().metadata,
  //             ),
  //             checkExisting: false,
  //           );
  //           registry.removeDependencyK(
  //             typeEntity,
  //             groupEntity: g,
  //           );
  //           return value;
  //         }()),
  //       );
  //     case Object _:
  //       return Ok(Some(value));
  //   }
  // }

  //
  //
  //

  // Result<Option<Dependency<Object>>> _registerDependencyK({
  //   required Dependency<Object> dependency,
  //   bool checkExisting = false,
  // }) {
  //   final g = dependency.metadata.fold((e) => e.groupEntity, () => focusGroup);
  //   final typeEntity = dependency.typeEntity;
  //   if (checkExisting) {
  //     final dep = _getDependencyK(
  //       typeEntity,
  //       groupEntity: g,
  //       traverse: false,
  //     );
  //     if (dep.isErr()) {
  //       return dep.err().cast();
  //     }
  //     if (dep.unwrap().isSome()) {
  //       return const Err('Dependency already registered.');
  //     }
  //   }
  //   registry.setDependency(dependency);
  //   return Ok(Some(dependency));
  // }

  //
  //
  //

  Result<Option<Dependency<Resolvable<Object>>>> _getDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool validate = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    var dep = registry
        .getDependencyK(typeEntity, groupEntity: g)
        .or(registry.getDependencyK(TypeEntity(Future, [typeEntity]), groupEntity: g));
    if (dep.isNone() && traverse) {
      for (final parent in parents) {
        final test = (parent as SupportsMixinK)._getDependencyK(
          typeEntity,
          groupEntity: g,
        );
        if (test.isErr()) {
          return test;
        }
        dep = test.unwrap();
        if (dep.isSome()) {
          break;
        }
      }
    }
    if (dep.isSome()) {
      final dependency = dep.unwrap() as Dependency;
      if (validate) {
        final metadata = dependency.metadata;
        if (metadata.isSome()) {
          final valid = metadata.unwrap().validator.map((e) => e(dependency));
          if (valid.isSome() && !valid.unwrap()) {
            return Err(
              stack: [SupportsMixinK, _getDependencyK],
              error: 'Dependency validation failed.',
            );
          }
        }
      }
      return Ok(Some(dependency.cast()));
    }
    return const Ok(None());
  }

  //
  //
  //

  // @protected
  // Option<Resolvable<Object>> unregisterK(
  //   Entity typeEntity, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool skipOnUnregisterCallback = false,
  // }) {
  //   final g = groupEntity.isDefault() ? focusGroup : groupEntity;
  //   final removed = registry
  //       .removeDependencyK(typeEntity, groupEntity: g)
  //       .or(registry.removeDependencyK(TypeEntity(Future, [typeEntity]), groupEntity: g))
  //       .or(registry.removeDependencyK(TypeEntity(Lazy, [typeEntity]), groupEntity: g));
  //   if (removed.isNone) {
  //     return const None();
  //   }
  //   final removedDependency = removed.unwrap() as Dependency;
  //   if (skipOnUnregisterCallback) {
  //     return Some(removedDependency.value);
  //   }
  //   final metadata = removedDependency.metadata;
  //   if (metadata.isSome) {
  //     final onUnregister = metadata.unwrap().onUnregister;
  //     if (onUnregister.isSome) {
  //       return Some(
  //         consec(
  //           onUnregister.unwrap()(removedDependency),
  //           (_) => removedDependency,
  //         ),
  //       );
  //     }
  //   }
  //   return Some(removedDependency.value);
  // }

  //
  //
  //

  @protected
  bool isRegisteredK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    if (registry.containsDependencyK(typeEntity, groupEntity: g) ||
        registry.containsDependencyK(TypeEntity(Future, [typeEntity]), groupEntity: g) ||
        registry.containsDependencyK(TypeEntity(Lazy, [typeEntity]), groupEntity: g)) {
      return true;
    }
    if (traverse) {
      for (final parent in parents) {
        if ((parent as SupportsMixinK).isRegisteredK(typeEntity, groupEntity: g, traverse: true)) {
          return true;
        }
      }
    }
    return false;
  }

  //
  //
  //

  // Result<Option<Resolvable<Object>>> untilK(
  //   Entity typeEntity, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final g = groupEntity.isDefault() ? focusGroup : groupEntity;
  //   final test = getK(typeEntity, groupEntity: g);
  //   if (test.isErr) {
  //     return test.err.cast();
  //   }
  //   if (test.unwrap().isSome) {
  //     return test;
  //   }
  //   if (completers.isSome) {
  //     final dep = completers.unwrap().registry.getDependencyK(
  //           TypeEntity(CompleterOr<Resolvable<Object>>, [typeEntity]),
  //           groupEntity: g,
  //         );
  //     final completer = dep.unwrap().value as CompleterOr<Resolvable<Object>>;
  //     return Ok(Some(completer.futureOr.thenOr((e) => e)));
  //   }

  //   if (completers.isNone) {
  //     completers = Some(DIBase());
  //   }

  //   final completer = CompleterOr<Resolvable<Object>>();
  //   completers.unwrap().registry.setDependency(
  //         Dependency<CompleterOr<Resolvable<Object>>>(
  //           completer,
  //           metadata: Some(
  //             DependencyMetadata(
  //               groupEntity: g,
  //             ),
  //           ),
  //         ),
  //       );

  //   return Ok(
  //     Some(
  //       completer.futureOr.thenOr((value) {
  //         completers.unwrap().registry.removeDependencyK(
  //               TypeEntity(CompleterOr<Resolvable<Object>>, [typeEntity]),
  //               groupEntity: g,
  //             );
  //         return getK(
  //           typeEntity,
  //           groupEntity: groupEntity,
  //           traverse: traverse,
  //         ).unwrap().unwrap();
  //       }),
  //     ),
  //   );
  // }
}
