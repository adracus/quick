library quick.test.middleware;

import 'dart:async' show Future, runZoned;

import 'package:quick/quick.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart' hide Matcher;

import 'mock.dart';

class TestBodyParser extends Object with BodyParser {
  var applyFunc;
  
  TestBodyParser(ErrorHandlerFn onError, this.applyFunc) {
    this.onError = onError;
  }
  
  bool shouldApply(Request request) => true;
  
  Future apply(Request request) => applyFunc(request);
}

main() => defineTests();

defineTests() {
  group("BodyParser", () {
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
        var parser = new TestBodyParser(expectAsync((err, request, response, next) {
          expect(err, equals("Should be caught"));
        }), (request) {
          throw "Should be caught";
        });
        
        parser.handlerFn(null, null, null);
      });
    });
  });
}