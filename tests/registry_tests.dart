import 'package:df_di/src/_internal.dart';
import 'package:df_di/src/test_di.dart';
import 'package:test/test.dart';

void main() {
  group('Testing ', () {
    test('int 1', () {
      final registry = DIRegistry();
      final dependency = Dependency<int>(1);
      registry.setDependency<int>(dependency);
      expect(
        dependency,
        registry.getDependencyOrNull<int>(),
      );
      expect(
        dependency,
        registry.getDependencyWithKeyOrNull(DIKey(int)),
      );
    });
    test('int 2', () {
      final registry = DIRegistry();
      final dependency = Dependency<int>(1);
      registry.setDependency<int>(dependency);
      expect(
        dependency,
        registry.getDependencyOrNull<int>(),
      );
      expect(
        dependency,
        registry.getDependencyWithKeyOrNull(DIKey(int)),
      );
    });
  });
}
