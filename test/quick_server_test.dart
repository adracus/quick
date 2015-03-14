library quick.server.test;

import 'package:quick/quick.dart';
import 'package:unittest/unittest.dart';

main() => defineTests();

var ct = 0;

defineTests() {
  var server = new Server();
  
  server.router.middleware
    ..add(new LogMiddleware());
  
  server.router.routes
    ..get("/", (request, response) {
      response.status(200).send("Everything allright");
    });
  
  server.router.errorHandlers
    ..use((error, request, response, next) {
      if (error is RouteNotFound) {
        response.status(404).send("Not found");
      }
    })
    ..use((error, request, response, next) {
      print(error);
      response.status(500).send("Internal server error");
    });
  
  server.listen();

}