library quick.server.test;

import 'package:quick/quick.dart';
import 'package:unittest/unittest.dart';

main() => defineTests();

var ct = 0;

defineTests() {
  var server = new Server();
  
  server.router.middleware
    ..add(const LogMiddleware());
  
  server.router.routes
    ..get("/", (request, response) {
      response.status(200).send("Everything allright");
    })
    ..get("/users/:name", (request, response) {
      response.status(200).send(request.parameters["name"]);
    });
  
  server.router.errorHandlers
    ..add(const RouteNotFoundHandler())
    ..add(const UncaughtErrorHandler());
  
  server.listen();

}