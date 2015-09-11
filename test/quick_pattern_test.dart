library quick.test.pattern;

import 'package:unittest/unittest.dart';
import 'package:quick/quick.dart';

main() => defineTests();

defineTests() {
  group("UrlMatcher", () {
    test("Constructor", () {
      var matcher = new UrlMatcher.parse("/repo/:test/:param");
      expect(matcher.keys.keys, equals({"test": 2, "param": 3}));
      expect(matcher.regex.pattern, equals(r"/repo/\w+/\w+"));
    });

    test("parameters", () {
      var matcher = new UrlMatcher.parse("/:id/:username/:repo");
      var parameters = matcher.parameters("/123/user/quick");
      expect(parameters,
          equals({"id": "123", "username": "user", "repo": "quick"}));
    });

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

    test("==", () {
      var m1 = new UrlMatcher.parse("/repo/:id/:username");
      var m2 = new UrlMatcher.parse("/repo/:id/:username");
      var m3 = new UrlMatcher.parse("/repo/:identifier/:name");
      var m4 = new UrlMatcher.parse("/notrepo");

      expect(m1, equals(m2));
      expect(m1, equals(m3));
      expect(m1, isNot(equals(m4)));
    });

    test("hashCode", () {
      var m1 = new UrlMatcher.parse("/repo/:id/:username");
      var m2 = new UrlMatcher.parse("/repo/:id/:username");
      var m3 = new UrlMatcher.parse("/repo/:identifier/:name");
      var m4 = new UrlMatcher.parse("/notrepo");

      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1.hashCode, equals(m3.hashCode));
      expect(m1.hashCode, isNot(equals(m4.hashCode)));
    });
  });

  group("UrlKeys", () {
    group("Constructor", () {
      var keys = new UrlKeys.parse("/:id/:test");
      expect(keys.keys, equals({"id": 1, "test": 2}));
    });

    group("parseKeys", () {
      test("invalid path", () {
        expect(() => UrlKeys.parseKeys("/:id/:id"), throws);
        expect(() => UrlKeys.parseKeys("/:id/:idnot"), returnsNormally);
      });

      test("valid path", () {
        var keys = UrlKeys.parseKeys("/:id/:username/:repo");
        expect(keys, equals({"id": 1, "username": 2, "repo": 3}));
      });
    });

    test("parameters", () {
      var keys = new UrlKeys.parse("/:id/:username/:repo");
      var parameters = keys.parameters("/123/user/quick");
      expect(parameters,
          equals({"id": "123", "username": "user", "repo": "quick"}));
    });
  });
}
