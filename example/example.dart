import 'package:quick/quick.dart';

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
