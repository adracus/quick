library quick.test.handler;

import 'package:unittest/unittest.dart' hide Matcher;
import 'package:quick/quick.dart';
import 'package:mock/mock.dart';

class TestHandlerIterable extends Object with HandlerIterable {
  final Mock handlers = new Mock();
  createHandler(Matcher matcher, handlerFn) => new TestHandler(handlerFn, matcher);
  matching(String method, String path) => null;
}

@proxy
class TestHandler extends Mock implements Handler {
  var handlerFn;
  Matcher matcher;
  
  TestHandler(this.handlerFn, this.matcher);
  
  bool matches(String method, String path) => true;
  
  operator==(other) {
    if (other is! TestHandler) return false;
    return handlerFn == other.handlerFn &&
           matcher == other.matcher;
  }
}


main() => defineTests();

defineTests() {
  group("Matcher", () {
    test("total", () {
      var matcher = new Matcher.total();
      expect(matcher.matcher, equals(new UrlMatcher.parse("/.*")));
      expect(matcher.methods, equals(new MethodSet.all()));
    });
    
    test("matches", () {
      var matcher = new Matcher(new MethodSet.get(), "/this/is/:path");
      
      expect(matcher.matches("GET", "/this/is/here"), isTrue);
      expect(matcher.matches("POST", "/this/is/here"), isFalse);
      expect(matcher.matches("GET", "/this/is"), isFalse);
    });
    
    test("==", () {
      var m1 = new Matcher(new MethodSet.get(), "/this/is/:path");
      var m2 = new Matcher(new MethodSet.get(), "/this/is/:path");
      var m3 = new Matcher(new MethodSet.post(), "/this/is/:path");
      var m4 = new Matcher(new MethodSet.get(), "/this/is/notpath");
      var m5 = new Matcher.total();
      
      expect(m1, equals(m2));
      expect(m1, isNot(equals(m3)));
      expect(m1, isNot(equals(m4)));
      expect(m1, isNot(equals(m5)));
    });
    
    test("hashCode", () {
      var m1 = new Matcher(new MethodSet.get(), "/this/is/:path");
      var m2 = new Matcher(new MethodSet.get(), "/this/is/:path");
      var m3 = new Matcher(new MethodSet.post(), "/this/is/:path");
      var m4 = new Matcher(new MethodSet.get(), "/this/is/notpath");
      var m5 = new Matcher.total();
      
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1.hashCode, isNot(equals(m3.hashCode)));
      expect(m1.hashCode, isNot(equals(m4.hashCode)));
      expect(m1.hashCode, isNot(equals(m5.hashCode)));
    });
  });
  
  group("HandlerIterable", () {
    void testHandlerIterableAdderFunction(MethodSet methodSet,
                void f(TestHandlerIterable iterable, handlerFn),
                {String path: "/path"}) {
      var iterable = new TestHandlerIterable();
      var handlerFn = (some) => "test";
      var matcher = new Matcher(methodSet, path);
      var handler = new TestHandler(handlerFn, matcher);
      iterable.handlers
        .when(callsTo("add", handler))
        .alwaysReturn(null);
      
      f(iterable, handlerFn);
      
      iterable.handlers.calls("add", handler).verify(happenedOnce);
    }
    
    test("get", () {
      testHandlerIterableAdderFunction(new MethodSet.get(), (iterable, handlerFn) {
        iterable.get("/path", handlerFn);
      });
    });
    
    test("post", () {
      testHandlerIterableAdderFunction(new MethodSet.post(), (iterable, handlerFn) {
        iterable.post("/path", handlerFn);
      });
    });
    
    test("put", () {
      testHandlerIterableAdderFunction(new MethodSet.put(), (iterable, handlerFn) {
        iterable.put("/path", handlerFn);
      });
    });
    
    test("delete", () {
      testHandlerIterableAdderFunction(new MethodSet.delete(), (iterable, handlerFn) {
        iterable.delete("/path", handlerFn);
      });
    });
    
    test("head", () {
      testHandlerIterableAdderFunction(new MethodSet.head(), (iterable, handlerFn) {
        iterable.head("/path", handlerFn);
      });
    });
    
    test("trace", () {
      testHandlerIterableAdderFunction(new MethodSet.trace(), (iterable, handlerFn) {
        iterable.trace("/path", handlerFn);
      });
    });
    
    test("connect", () {
      testHandlerIterableAdderFunction(new MethodSet.connect(), (iterable, handlerFn) {
        iterable.connect("/path", handlerFn);
      });
    });
    
    test("all", () {
      testHandlerIterableAdderFunction(new MethodSet.all(), (iterable, handlerFn) {
        iterable.all("/path", handlerFn);
      });
    });
    
    test("get", () {
      testHandlerIterableAdderFunction(new MethodSet.get(), (iterable, handlerFn) {
        iterable.get("/path", handlerFn);
      });
    });
    
    test("use", () {
      testHandlerIterableAdderFunction(new MethodSet.all(), (iterable, handlerFn) {
        iterable.use(handlerFn);
      }, path: "/.*");
    });
  });
  
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