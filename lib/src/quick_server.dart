library quick.server;

import 'dart:io';
import 'dart:async' show Future;

import 'quick_requests.dart';
import 'quick_router.dart';
import 'quick_util.dart';

class Server {
  final Directive _directive;

  Server(this._directive);

  int _port;
  String _address;

  /** Listens on the specified port and address. Returns a future
   * when listening. */
  Future start({int port: 8080, String address: "0.0.0.0"}) {
    _port = port;
    _address = address;
    return HttpServer.bind(address, port).then((server) async {
      final contexts = server.map((request) => new Context.transform(request));
      _directive.handle(contexts);
    });
  }

  int get port => _port;
  String get address => _address;
}

/** A pair of both request and response */
class Context {
  /** An http request. */
  final Request request;

  /** An http response. */
  final Response response;

  /** Creates a new [Context] */
  Context(this.request, this.response);

  /** Transforms an existing [HttpRequest] into a [Context]. */
  factory Context.transform(HttpRequest httpRequest) {
    var request = new Request(httpRequest);
    var response = new Response(httpRequest.response);
    return new Context(request, response);
  }

  void complete([toStringEvaluatable]) {
    if (null == toStringEvaluatable) {
      response.close();
      return;
    }

    final string = eval(toStringEvaluatable);
    assert(string is String);
    response.send(string);
  }

  bool get isDone => response.isSent;
  bool get isNotDone => !isDone;
}
