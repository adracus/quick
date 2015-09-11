library quick.test.route;

import 'package:quick/quick.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart' hide Matcher;

import 'mock.dart';

main() => defineTests();

defineTests() {
  group("BaseRoute", () {
    test("==", () {
      var b1 = new BaseRoute(new Matcher.total(), null);
      var b2 = new BaseRoute(new Matcher.total(), (req, res) => null);
      var b3 = new BaseRoute(new Matcher(new MethodSet.get(), "/path"), null);
      var b4 = new BaseRoute(new Matcher.total(), null);

      expect(b1, equals(b2));
      expect(b1, isNot(equals(b3)));
      expect(b1, equals(b4));
    });

    test("hashCode", () {
      var b1 = new BaseRoute(new Matcher.total(), null);
      var b2 = new BaseRoute(new Matcher.total(), (req, res) => null);
      var b3 = new BaseRoute(new Matcher(new MethodSet.get(), "/path"), null);
      var b4 = new BaseRoute(new Matcher.total(), null);

      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1.hashCode, isNot(equals(b3.hashCode)));
      expect(b1.hashCode, equals(b4.hashCode));
    });
  });

  group("RouteSet", () {
    test("matching", () {
      var set = new RouteSet();
      set.get("/test", (req, res) => 0);
      set.get("/test", (req, res) => 1);
      set.get("/nottest", (req, res) => 2);

      expect(set.matching("GET", "/test").handlerFn(null, null), equals(0));
      expect(set.matching("GET", "/nottest").handlerFn(null, null), equals(2));
    });
  });

  group("NonExistentRoute", () {
    test("handlerFn", () {
      var ne = new NonExistentRoute();
      var requestMock = new MockRequest();
      requestMock.when(callsTo("get uri")).thenReturn(Uri.parse("/test"));

      bool threw = false;
      try {
        ne.handlerFn(requestMock, null);
      } on RouteNotFound catch (e) {
        threw = true;
        expect(e.uri, equals(Uri.parse("/test")));
      }
      expect(threw, isTrue);
    });

    test("matches", () {
      var ne = new NonExistentRoute();

      expect(ne.matches("test", "test"), isTrue);
    });
  });

  group("RouteNotFound", () {
    test("toString", () {
      var notFound = new RouteNotFound(Uri.parse("/path"));

      expect(notFound.toString(), equals("Could not find /path"));
    });
  });
}
