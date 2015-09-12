library quick.server;

import 'dart:io';
import 'dart:async' show Future;

import 'quick_requests.dart';
import 'quick_router.dart';

class Server {
  final Router router = new Router();

  int _port;
  String _address;

  /** Listens on the specified port and address. Returns a future
   * when listening. */
  Future listen({int port: 8080, String address: "0.0.0.0"}) {
    _port = port;
    _address = address;
    return HttpServer.bind(address, port).then((server) {
      return server.listen((request) {
        var pair = new RequestResponsePair.transform(request);
        return router.handle(pair.request, pair.response);
      });
    });
  }

  int get port => _port;
  String get address => _address;
}

/** A pair of both request and response */
class RequestResponsePair {
  /** An http request. */
  final Request request;

  /** An http response. */
  final Response response;

  /** Creates a new [RequestResponsePair] */
  RequestResponsePair(this.request, this.response);

  /** Transforms an existing [HttpRequest] into a [RequestResponsePair]. */
  factory RequestResponsePair.transform(HttpRequest httpRequest) {
    var request = new Request(httpRequest);
    var response = new Response(httpRequest.response);
    return new RequestResponsePair(request, response);
  }
}
