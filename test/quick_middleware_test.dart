library quick.test.middleware;

import 'dart:async' show Future, runZoned;

import 'package:quick/quick.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart' hide Matcher;

import 'mock.dart';

class TestBodyParser extends Object with BodyParser {
  var applyFunc;
  bool shouldApplyBool = true;

  TestBodyParser(ErrorHandlerFn onError, this.applyFunc) {
    this.onError = onError;
  }

  bool shouldApply(Request request) => shouldApplyBool;

  Future apply(Request request) => applyFunc(request);
}

main() => defineTests();

defineTests() {
  group("BodyParser", () {
    test("json", () {
      expect(new BodyParser.json(), new isInstanceOf<JsonBodyParser>());
    });

    test("text", () {
      expect(new BodyParser.text(), new isInstanceOf<TextBodyParser>());
    });

    test("urlEncoded", () {
      expect(new BodyParser.urlEncoded(),
          new isInstanceOf<UrlEncodedBodyParser>());
    });

    group("handlerFn", () {
      test("Regular handling", () {
        var mockRequest = new MockRequest();
        mockRequest.when(callsTo("set body", "Value")).thenReturn(null);
        var parser = new TestBodyParser(null, (request) {
          return new Future.value("Value");
        });

        parser.handlerFn(mockRequest, null, expectAsync(() {
          mockRequest.calls("set body", "Value").verify(happenedOnce);
        }));
      });

      test("Call next if no handling", () {
        var parser = new TestBodyParser(null, null);
        parser.shouldApplyBool = false;
        parser.handlerFn(null, null, expectAsync(() {}));
      });

      test("Handling without internal onError function", () {
        var parser = new TestBodyParser(null, (request) {
          throw "Should not be caught";
        });

        runZoned(() {
          parser.handlerFn(null, null, null);
        }, onError: expectAsync((e) {
          expect(e, equals("Should not be caught"));
        }));
      });

      test("Handling with internal onError function", () {
        var parser =
            new TestBodyParser(expectAsync((err, request, response, next) {
          expect(err, equals("Should be caught"));
        }), (request) {
          throw "Should be caught";
        });

        parser.handlerFn(null, null, null);
      });
    });
  });

  group("TextBodyParser", () {
    test("shouldApply", () {
      var request = new MockRequest();
    });
  });
}
