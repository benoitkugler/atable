import 'package:atable/logic/env.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test('test name', () {
    const envDev = Env(BuildMode.dev);
    print(envDev.importSejourLink("xxx"));
    print(envDev.urlFor("/root", queryParameters: {"test": "2"}));

    const envProd = Env(BuildMode.prod);
    print(envProd.importSejourLink("xxx"));
    print(envProd.urlFor("/root", queryParameters: {"test": "2"}));
  });
}
