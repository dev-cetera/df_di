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

void main() {
  // ---------------------------------------------------------------------------
  group(
    'Testing groups',
    () {
      test(
        '- Testing groups state and clear',
        () {
          final registry = DIRegistry(
            onChange: (state) {
              print('CHANGED: ${state.length}');
            },
          );
          registry.setDependency(Dependency(1));
          expect(
            registry.groupKeys.length,
            1,
          );
          expect(
            registry.state.toString(),
            "{null: {int: Instance of 'Dependency<int>'}}",
          );
          registry.removeGroup();
          expect(
            registry.groupKeys.length,
            0,
          );
          expect(
            registry.state.toString(),
            '{}',
          );
          registry.setGroup(
            {DIKey(int): Dependency(1)},
            groupKey: DIKey.defaultGroup,
          );
          expect(
            registry.groupKeys.length,
            1,
          );
          expect(
            registry.getGroup(groupKey: DIKey.defaultGroup).toString(),
            "{int: Instance of 'Dependency<Object>'}",
          );
          registry.clear();
          expect(
            registry.getGroup(),
            null,
          );
          expect(
            registry.state.toString(),
            '{}',
          );
        },
      );
    },
  );
  // ---------------------------------------------------------------------------
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
            registry.getDependencyOfRuntimeTypeOrNull(int),
            dependency,
          );
          expect(
            registry.getDependencyWithKeyOrNull(DIKey(int)),
            dependency,
          );
          expect(
            registry.getDependencyWithKeyOrNull(DIKey(' i n t ')),
            dependency,
          );
          expect(
            registry.getDependenciesWhere((test) => test.typeKey == DIKey(int)).firstOrNull,
            dependency,
          );
          expect(
            registry.getDependenciesWhere((test) => test.value.runtimeType == int).firstOrNull,
            dependency,
          );
          expect(
            registry.getDependenciesWhere((test) => test.value is int).firstOrNull,
            dependency,
          );
          expect(
            registry.containsDependency<int>(),
            true,
          );
          expect(
            registry.containsDependencyOfRuntimeType(int),
            true,
          );
          expect(
            registry.containsDependencyWithKey(DIKey(int)),
            true,
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
            registry.getDependencyOrNull<Future<int>>(),
            dependency,
          );
          expect(
            registry.getDependencyOfRuntimeTypeOrNull(Future<int>),
            dependency,
          );
          expect(
            registry.getDependencyWithKeyOrNull(DIKey.type(Future, [int])),
            dependency,
          );
          expect(
            registry.getDependencyWithKeyOrNull(DIKey(' F u t u r e < i n t > ')),
            dependency,
          );
          expect(
            registry
                .getDependenciesWhere((test) => test.typeKey == DIKey.type(Future, [int]))
                .firstOrNull,
            dependency,
          );
          expect(
            registry.getDependenciesWhere((test) {
              return test.value.runtimeType.toString() == (Future<int>).toString();
            }).firstOrNull,
            dependency,
          );
          expect(
            registry.getDependenciesWhere((test) => test.value is Future<int>).firstOrNull,
            dependency,
          );
          expect(
            registry.containsDependency<Future<int>>(),
            true,
          );
          expect(
            registry.containsDependencyOfRuntimeType(Future<int>),
            true,
          );
          expect(
            registry.containsDependencyWithKey(DIKey(Future<int>)),
            true,
          );
        },
      );
    },
  );
}
