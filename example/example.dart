import 'package:quick/quick.dart';

main() {
  var app = new Server();

  // Middleware that logs each request
  app.router.add(new LogMiddleware());

  // Error handler that catches if routes are not found and sends 404
  app.router.add(new RouteNotFoundHandler());

  // Error handler that catches all other uncaught exceptions
  app.router.add(new UncaughtErrorHandler());

  app.router.get("/", (Request request, Response response) {
    response.status(200).send("Hello World");
  });

  app.router.get("/:param1/:param2", (Request request, Response response) {
    final message = "URL parameters like ${request.parameters["param1"]} " +
        "and ${request.parameters["param2"]} also work.";
    response.status(200).send(message);
  });

  // Default port is 8080, interface 0.0.0.0
  app.listen().then((_) {
    print("Listening on ${app.port}");
  });
}
