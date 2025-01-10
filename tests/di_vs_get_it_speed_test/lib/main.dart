import 'comparisons/b1.dart';
import 'comparisons/b2.dart';
import 'comparisons/b3.dart';
import 'comparisons/b4.dart';
import 'comparisons/b5.dart';

void main() async {
  await b1();
  await b2();
  await b3();
  await b4();
  await b5();
  // GetIt seems to have a slight but neglible edge when it comes to registering
  // dependencies, while DI has a slight but neglible edge when it comes to
  // getting dependencies.
  //
  // Speed is more important when getting dependencies than when registering
  // dependencies.
}
