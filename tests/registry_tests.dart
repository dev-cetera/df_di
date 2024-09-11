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

import 'package:df_di/df_di.dart';
import 'package:df_di/src/_dependency.dart';
import 'package:df_di/src/_registry.dart';

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
            registry.groupKeys.length,
          );
          expect(
            "{null: {int: Instance of 'Dependency<int>'}}",
            registry.state.toString(),
          );
          registry.removeGroup();
          expect(
            0,
            registry.groupKeys.length,
          );
          expect(
            '{}',
            registry.state.toString(),
          );
          registry.setGroup(
            {DIKey(int): Dependency(1)},
            groupKey: DIKey.defaultGroup,
          );
          expect(
            1,
            registry.groupKeys.length,
          );
          expect(
            "{int: Instance of 'Dependency<Object>'}",
            registry.getGroup(groupKey: DIKey.defaultGroup).toString(),
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
          registry.setDependency<int>(dependency);
          expect(
            dependency,
            registry.getDependencyOrNull<int>(),
          );
          expect(
            dependency,
            registry.getDependencyOfRuntimeTypeOrNull(int),
          );
          expect(
            dependency,
            registry.getDependencyWithKeyOrNull(DIKey(int)),
          );
          expect(
            dependency,
            registry.getDependencyWithKeyOrNull(DIKey(' i n t ')),
          );
          expect(
            dependency,
            registry.dependencies.where((test) => test.typeKey == DIKey(int)).firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies.where((test) => test.value.runtimeType == int).firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies.where((test) => test.value is int).firstOrNull,
          );
          expect(
            true,
            registry.containsDependency<int>(),
          );
          expect(
            true,
            registry.containsDependencyOfRuntimeType(int),
          );
          expect(
            true,
            registry.containsDependencyWithKey(DIKey(int)),
          );
        },
      );
      test(
        '- Testing basics with Future<int>',
        () {
          final registry = DIRegistry();
          final dependency = Dependency<Future<int>>(Future.value(1));
          registry.setDependency<Future<int>>(dependency);
          expect(
            dependency,
            registry.getDependencyOrNull<Future<int>>(),
          );
          expect(
            dependency,
            registry.getDependencyOfRuntimeTypeOrNull(Future<int>),
          );
          expect(
            dependency,
            registry.getDependencyWithKeyOrNull(DIKey.type(Future, [int])),
          );
          expect(
            dependency,
            registry.getDependencyWithKeyOrNull(DIKey(' F u t u r e < i n t > ')),
          );
          expect(
            dependency,
            registry.dependencies
                .where((test) => test.typeKey == DIKey.type(Future, [int]))
                .firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies.where((test) {
              return test.value.runtimeType.toString() == (Future<int>).toString();
            }).firstOrNull,
          );
          expect(
            dependency,
            registry.dependencies.where((test) => test.value is Future<int>).firstOrNull,
          );
          expect(
            true,
            registry.containsDependency<Future<int>>(),
          );
          expect(
            true,
            registry.containsDependencyOfRuntimeType(Future<int>),
          );
          expect(
            true,
            registry.containsDependencyWithKey(DIKey(Future<int>)),
          );
        },
      );
    },
  );
}
