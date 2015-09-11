import 'package:quick/quick.dart';

main() {
  var app = new Server();

  app.router.add(new LogMiddleware());
  app.router.add(new RouteNotFoundHandler());

  app.router.get("/", (Request request, Response response) {
    response.status(200).send("Hello World");
  });

  app.listen().then((_) {
    print("Listening...");
  });
}
