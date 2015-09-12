# quick

quick is a web server implementation for the dart programming language. It
is heavily inspired by [lvivski's start](https://github.com/lvivski/start)
(which is unfortunately not developed anymored) and the all-known express
for node.

quick features a middleware, route and error handler architecture and has
fast setup as well as easy extensibility in mind.

## Installation

To install quick, you need to depend on it in your `pubspec.yaml`. Therefore,
add the following:

```yaml
dependencies:
  quick: ">=0.0.1 < 0.1.0"
```

Then in your code, import it as follows:

```dart
import 'package:quick/quick.dart';
```

## Usage

quick focuses on fast startup and a fast learning experience considered that
it is quite similar to express.

To create and start a server, first create one. Then, route handlers, middleware
and error handlers can be added. They differentiate by their function signature:
Routes have the signature `(Request request, Response response)`, middleware
`(Request request, Response response, next)` and error handlers
`(error, Request request, Response response, next)`, as known from express.

Additionally, quick comes with some predefined middleware such as
json, urlencoded and text body parsers, logging middleware and error handlers.

An example of using quick can be seen below:

```dart
main() {
  var app = new Server();

  // Middleware that logs each request
  app.router.add(new LogMiddleware());

  // Error handler that catches if routes are not found and sends 404
  app.router.add(new RouteNotFoundHandler());

  // Error handler that catches all other uncaught exceptions
  app.router.add(new UncaughtErrorHandler());

  // Body parsing middleware. This one's for parsing json. */
  app.router.add(new BodyParser.json());

  app.router.get("/", (Request request, Response response) {
    response.status(200).send("Hello World");
  });

  app.router.post("/message", (Request request, Response response) {
    var body = request.body as Map;
    if (!body.containsKey("message")) {
      return response.status(400).send("No message specified");
    }
    return response.status(200).send("Your message was '${body["message"]}'");
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
```

## Further Development

Contributions are always appreciated. When contributing, pull requesting or
else, please think about writing tests.
