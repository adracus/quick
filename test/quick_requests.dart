library quick.test.requests;

import 'package:quick/quick.dart';
import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';

import 'mock.dart';

main() => defineTests();

defineTests() {
  group("Request", () {
    test("accepts", () {
      var req = new MockHttpRequest();
      var headers = new MockHeaders();
      
      req.when(callsTo("get headers"))
        .alwaysReturn(headers);
      headers.when(callsTo("[]", "accept"))
        .alwaysReturn(["text/html", "application/json"]);
      
      var request = new Request(req);
      expect(request.accepts("text/html"), isTrue);
      expect(request.accepts("application/json"), isTrue);
      expect(request.accepts("application/xml"), isFalse);
      
      req.calls("get headers").verify(happenedExactly(3));
      headers.calls("[]").verify(happenedExactly(3));
    });
    
    test("[]", () {
      var req = new Request(null);
      
      req["test"] = "value";
      expect(req["test"], equals("value"));
    });
    
    test("header", () {
      var req = new MockHttpRequest();
      var headers = new MockHeaders();
      
      req.when(callsTo("get headers"))
        .alwaysReturn(headers);
      headers.when(callsTo("[]", "accept"))
        .alwaysReturn(["text/html", "application/json"]);
      headers.when(callsTo("[]", "content-type"))
        .alwaysReturn(["application/json"]);
      
      var request = new Request(req);
      expect(request.header("accept"), equals(["text/html", "application/json"]));
      expect(request.header("Accept"), equals(["text/html", "application/json"]));
      expect(request.header("aCCePt"), equals(["text/html", "application/json"]));
      expect(request.header("content-type"), equals(["application/json"]));
      
      req.calls("get headers").verify(happenedExactly(4));
      headers.calls("[]").verify(happenedExactly(4));
    });
    
    test("isMime", () {
      var req = new MockHttpRequest();
      var headers = new MockHeaders();
      
      req.when(callsTo("get headers"))
        .alwaysReturn(headers);
      headers.when(callsTo("[]", "content-type"))
        .alwaysReturn(["application/json"]);
      
      var request = new Request(req);
      
      expect(request.isMime("application/json"), isTrue);
      expect(request.isMime("text/html"), isFalse);
      
      req.calls("get headers").verify(happenedExactly(2));
      headers.calls("[]").verify(happenedExactly(2));
    });
  });
}