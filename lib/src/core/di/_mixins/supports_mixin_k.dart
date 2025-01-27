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
  Option<Resolvable<Object>> getK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = getDependencyK(
      typeEntity,
      groupEntity: g,
      traverse: traverse,
    );
    if (test.isNone()) {
      return const None();
    }
    final result = test.unwrap();
    if (result.isErr()) {
      return Some(Sync(result.err().castErr()));
    }
    final value = result.unwrap().value;
    if (value.isSync()) {
      return Some(value);
    }

    return Some(
      Async.unsafe(
        () => value.async().unwrap().value.then((e) {
          final value = e.unwrap();
          _registerDependencyK(
            dependency: Dependency(
              Sync(Ok(value)),
              metadata: test.unwrap().unwrap().metadata,
            ),
            checkExisting: false,
          );
          registry.removeDependencyK(
            TypeEntity(Async<Object>, [value.runtimeType]),
            groupEntity: g,
          );
          return value;
        }),
      ),
    );
  }

  //
  //
  //

  @protected
  Option<Result<Dependency<Object>>> getDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool validate = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = registry.getDependencyK(typeEntity, groupEntity: g);
    var temp = test.map((e) => Ok(e).result());
    if (test.isNone() && traverse) {
      for (final parent in parents) {
        temp = (parent as SupportsMixinK).getDependencyK(
          typeEntity,
          groupEntity: g,
        );
        if (temp.isSome()) {
          break;
        }
      }
    }

    if (temp.isSome()) {
      if (validate) {
        final result = temp.unwrap();
        if (result.isErr()) {
          return Some(result);
        }
        final dependency = result.unwrap();
        final metadata = dependency.metadata;
        if (metadata.isSome()) {
          final valid = metadata.unwrap().validator.map((e) => e(dependency));
          if (valid.isSome() && !valid.unwrap()) {
            return const Some(
              Err(
                stack: ['SupportsMixinK', 'getDependencyK'],
                error: 'Dependency validation failed.',
              ),
            );
          }
        }
      }
    }
    return temp;
  }

  //
  //
  //

  Result<Dependency<Object>> _registerDependencyK({
    required Dependency<Object> dependency,
    bool checkExisting = false,
  }) {
    // ignore: invalid_use_of_visible_for_testing_member
    final g = dependency.metadata.isSome() ? dependency.metadata.unwrap().groupEntity : focusGroup;
    if (checkExisting) {
      final test = getDependencyK(
        dependency.typeEntity,
        groupEntity: g,
        traverse: false,
        validate: false,
      );
      if (test.isSome()) {
        return const Err(
          stack: ['DIBase', '_registerDependency'],
          error: 'Dependency already registered.',
        );
      }
    }
    registry.setDependency(dependency);
    return Ok(dependency);
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
  //   final g = groupEntity.preferOverDefault(focusGroup);
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
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependencyK(typeEntity, groupEntity: g)
        // TODO:
        //|| registry.containsDependencyK(TypeEntity(Lazy, [typeEntity]), groupEntity: g)
        ) {
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
  //   final g = groupEntity.preferOverDefault(focusGroup);
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
