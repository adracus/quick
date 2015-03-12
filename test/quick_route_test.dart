library quick.test.route;

import 'package:quick/quick.dart';
import 'package:unittest/unittest.dart';

main() => defineTests();

defineTests() {
  group("MethodSet", () {
    test("validMethodSet", () {
      var validSet = new Set.from(["GET", "POST", "HEAD"]);
      var invalidSet = new Set.from(["NON", "EXISTING", "METHODS"]);
      
      expect(MethodSet.validMethodSet(validSet), isTrue);
      expect(MethodSet.validMethodSet(invalidSet), isFalse);
    });
    
    test("==", () {
      var m1 = new MethodSet(["GET", "PUT"]);
      var m2 = new MethodSet(["GET", "PUT"]);
      var m3 = new MethodSet(["POST"]);
      
      expect(m1, equals(m1));
      expect(m1, equals(m2));
      expect(m1, isNot(equals(m3)));
    });
    
    test("matches", () {
      var m1 = new MethodSet(["GET", "PUT"]);
      
      expect(m1.matches("NOMETHOD"), isFalse);
      expect(m1.matches("GET"), isTrue);
      expect(m1.matches("PUT"), isTrue);
    });
    
    test("hashCode", () {
      var m1 = new MethodSet(["GET", "PUT"]);
      var m2 = new MethodSet(["GET", "PUT"]);
      var m3 = new MethodSet(["POST"]);
      
      expect(m1.hashCode, equals(m1.hashCode));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1.hashCode, isNot(equals(m3.hashCode)));
    });
    
    test("validateMethods", () {
      var validMethods = ["get", "post", "PUT"];
      var invalidMethods = ["non", "existing", "METHODS"];
      
      expect(MethodSet.validateMethods(validMethods),
          equals(new Set.from(["GET", "POST", "PUT"])));
      expect(() => MethodSet.validateMethods(invalidMethods), throws);
    });
  });
}