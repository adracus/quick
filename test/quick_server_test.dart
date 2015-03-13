library quick.server.test;

import 'package:quick/quick.dart';
import 'package:unittest/unittest.dart';

main() => defineTests();

var ct = 0;

defineTests() {
  var server = new Server();
  
  server.router.middleware
    ..use((request, response, next) {
      print("Request on ${request.uri}");
      next();
    })
    ..get("/", (request, response, next) {
      request.context["ct"] = ct++;
      if (3 == ct) throw "Some error";
      next();
    });
  
  server.router.routes
    ..get("/", (request, response) {
      response.status(200).send("Everything allright ${request.context["ct"]}");
    });
  
  server.router.errorHandlers
    ..use((error, request, response, next) {
      print(error);
      response.status(500).send("Internal server error");
    });
  
  server.listen();

}