# quick [![Build Status](https://travis-ci.org/Adracus/quick.svg?branch=master)](https://travis-ci.org/Adracus/quick)

quick is a web server implementation for the dart programming language. It
is heavily inspired by [lvivski's start](https://github.com/lvivski/start)
(which is unfortunately not developed anymored) and the spray webframework
for scala.

quick features the directive concept: A directive is something that handles
a stream and may also produce a streams. Imagine your webserver being a tree:
The request stream first meets the root directive. This directive may then
decide to handle the request or to transform it and output it in its own
stream. This stream is then passed onto the children of this directive and
is handled by the first directive that matches. That may sound a bit abstract
but see the usage in the following example.

## Installation

To install quick, you need to depend on it in your `pubspec.yaml`. Therefore,
add the following:

```yaml
dependencies:
  quick: ">=0.0.2 < 0.1.0"
```

Then in your code, import it as follows:

```dart
import 'package:quick/quick.dart';
```

## Usage

quick focuses on fast startup and a fast learning experience considered that
it is quite similar to spray.

To start, first create a directive. Then pass this directive to the creation
of a server which can then be started on a specified port and host.

Additionally, quick comes with some predefined middleware such as
json, urlencoded and text body parsers, logging middleware and error handlers.

An example of using quick can be seen below:

```dart
main() async {
  final route =
  logRoute - (
    get - (
      path("/ping")
        .listen((Context ctx) => ctx.complete("pong")) %
      path("/pong")
        .listen((Context ctx) => ctx.complete("ping")) %
      always((Context ctx) => ctx.complete("Not found"))
    ) %
    always((Context ctx) => ctx.complete("Other methods not supported"))
  );

  final app = new Server(route);
  app.start().then((_) {
    print("Listening");
  });
}
```

## Further Development

Contributions are always appreciated. When contributing, pull requesting or
else, please think about writing tests.
