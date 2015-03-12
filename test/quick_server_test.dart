library quick.server.test;

import 'package:quick/quick.dart';
import 'package:unittest/unittest.dart';

main() => defineTests();

defineTests() {
  Server.listen();
  
  group("Server", () {
    test("listen", () {
      
    });
  });
}