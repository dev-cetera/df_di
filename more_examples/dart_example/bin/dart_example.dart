// ignore_for_file: invalid_use_of_protected_member

import 'package:df_di/df_di.dart';

void main() async {
  DI.global.register(Future.delayed(const Duration(seconds: 1), () => 2));
  print(
    DI.global.registry.state.entries.first.value.values.first.value,
  ); // Async
  await DI.global.resolveAll().unwrap();
  print(
    DI.global.registry.state.entries.first.value.values.first.value,
  ); // Sync

  await Future.delayed(const Duration(milliseconds: 100), () {
    print(
      DI.global.registry.state.entries.first.value.values.first.value.value,
    );
  });

  final a1 = TypeEntity('minified:Class1377<Object>', [
    'minified:Class1377<Object>',
  ]);
  final b1 = TypeEntity('minified:Class1377<minified:Class1377<Object>>');
  print(a1 == b1); // expected true

  final a2 = TypeEntity(Service<Params>);
  final b2 = TypeEntity(Service, [Params]);
  print(a2 == b2); // expected true

  DI.global.register<List<int>>([42]);
  final answer = DI.global.getT(List<int>).unwrap().unwrap();
  final output = '${List<int>}: $answer';
  print(output);
}

// Testing Object? vs Object.
class Service<TParams extends Object?> {}

class Params extends Object {}
