import 'package:df_di/df_di.dart';

void main(List<String> arguments) {
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
