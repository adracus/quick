library quick.test.pattern;

import 'package:unittest/unittest.dart';
import 'package:quick/quick.dart';

main() => defineTests();

defineTests() {
  group("UrlMatcher", () {
    test("toRegex", () {
      var r1 = UrlMatcher.toRegex("/:test/:othertest");
      var r2 = UrlMatcher.toRegex("/route/:param");
      
      expect(r1.pattern, equals(r"/\w+/\w+"));
      expect(r2.pattern, equals(r"/route/\w+"));
    });
    
    test("matches", () {
      var matcher = new UrlMatcher.parse("/repo/:id/:username");
      
      expect(matcher.matches("/repo/test/other"), isTrue);
      expect(matcher.matches("/repo/test"), isFalse);
      expect(matcher.matches("/repo/test/otherandmore/more"), isFalse);
    });
  });
  
  group("UrlKeys", () {
    group("parseKeys", () {
      test("invalid path", () {
        expect(() => UrlKeys.parseKeys("/:id/:id"), throws);
        expect(() => UrlKeys.parseKeys("/:id/:idnot"), returnsNormally);
      });
      
      test("valid path", () {
        var keys = UrlKeys.parseKeys("/:id/:username/:repo");
        expect(keys, equals({
          "id": 1, "username": 2, "repo": 3
        }));
      });
    });
    
    test("parameters", () {
      var keys = new UrlKeys.parse("/:id/:username/:repo");
      var parameters = keys.parameters("/123/user/quick");
      expect(parameters, equals({
        "id": "123", "username": "user", "repo": "quick"
      }));
    });
  });
}