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

// ignore_for_file: invalid_use_of_protected_member

import 'package:df_di/df_di.dart';
import 'package:df_di/src/core/_dependency.dart';
import 'package:df_di/src/core/_registry.dart';

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  group(
    'Testing groups',
    () {
      test(
        '- Testing groups state and clear',
        () {
          final registry = DIRegistry(
            onChange: () {
              print('CHANGED!!!');
            },
          );
          registry.setDependency(Dependency(1));
          expect(
            1,
            registry.groupEntities.length,
          );
          expect(
            "{null: {int: Instance of 'Dependency<int>'}}",
            registry.state.toString(),
          );
          registry.removeGroup();
          expect(
            0,
            registry.groupEntities.length,
          );
          expect(
            '{}',
            registry.state.toString(),
          );
          registry.setGroup(
            {Entity(int): Dependency(1)},
            groupEntity: Entity.defaultGroup,
          );
          expect(
            1,
            registry.groupEntities.length,
          );
          expect(
            "{int: Instance of 'Dependency<Object>'}",
            registry.getGroup(groupEntity: Entity.defaultGroup).toString(),
          );
          registry.clear();
          expect(
            '{}',
            registry.getGroup().toString(),
          );
          expect(
            '{}',
            registry.state.toString(),
          );
        },
      );
    },
  );

  group(
    'Testing basics',
    () {
      test(
        '- Testing basics with int',
        () {
          final registry = DIRegistry();
          final dependency = Dependency<int>(1);
          registry.setDependency(dependency);
          expect(
            dependency,
            registry.getDependencyOrNull<int>(),
          );
          expect(
            dependency,
            registry.getDependencyOrNullT(int),
          );
          expect(
            dependency,
            registry.getDependencyOrNullK(Entity(int)),
          );
          expect(
            dependency,
            registry.getDependencyOrNullK(Entity(' i n t ')),
          );
          expect(
            dependency,
            registry.dependencies
                .where((test) => test.typeEntity == Entity(int))
                .firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies
                .where((test) => test.value.runtimeType == int)
                .firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies
                .where((test) => test.value is int)
                .firstOrNull,
          );
          expect(
            true,
            registry.containsDependency<int>(),
          );
          expect(
            true,
            registry.containsDependencyT(int),
          );
          expect(
            true,
            registry.containsDependencyK(Entity(int)),
          );
        },
      );
      test(
        '- Testing basics with Future<int>',
        () {
          final registry = DIRegistry();
          final dependency = Dependency<Future<int>>(Future.value(1));
          registry.setDependency(dependency);
          expect(
            dependency,
            registry.getDependencyOrNull<Future<int>>(),
          );
          expect(
            dependency,
            registry.getDependencyOrNullT(Future<int>),
          );
          expect(
            dependency,
            registry.getDependencyOrNullK(Entity.type(Future, [int])),
          );
          expect(
            dependency,
            registry.getDependencyOrNullK(Entity(' F u t u r e < i n t > ')),
          );
          expect(
            dependency,
            registry.dependencies
                .where((test) => test.typeEntity == Entity.type(Future, [int]))
                .firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies.where((test) {
              return test.value.runtimeType.toString() ==
                  (Future<int>).toString();
            }).firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies
                .where((test) => test.value is Future<int>)
                .firstOrNull,
          );
          expect(
            true,
            registry.containsDependency<Future<int>>(),
          );
          expect(
            true,
            registry.containsDependencyT(Future<int>),
          );
          expect(
            true,
            registry.containsDependencyK(Entity(Future<int>)),
          );
        },
      );
    },
  );
}
