import 'package:df_di/df_di.dart';

void main(List<String> arguments) {
  // final a = TypeEntity('minified:Class1377<Object>', ['minified:Class1377<Object>']);
  // final b = TypeEntity('minified:Class1377<minified:Class1377<Object>>');
  // print(a == b);

  final a = TypeEntity(Service<UserSessionServiceParams>);
  final b = TypeEntity(Service, [UserSessionServiceParams]);
  print(a == b); // false! Should be true

  // DI.global.register<List<int>>([42]);
  // final answer = DI.global.getT(List<int>).unwrap().unwrap();
  // final output = '${List<int>}: $answer';
  // print(output);
}


class Service<TParams extends Object?> {}

class UserSessionServiceParams extends Object {}
