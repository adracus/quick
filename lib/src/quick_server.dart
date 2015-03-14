library quick.server;

import 'dart:io';

import 'quick_requests.dart';
import 'quick_route.dart';


class Server {
  final Router router = new Router();
  
  void listen({int port: 8080, String address: "0.0.0.0"}) {
    HttpServer.bind(address, port).then((server) {
      
      server.listen((request) {
        var pair = new RequestResponsePair.transform(request);
        router.handle(pair.request, pair.response);
      });
    });
  }
}

class RequestResponsePair {
  final Request request;
  final Response response;
  
  RequestResponsePair(this.request, this.response);
  
  factory RequestResponsePair.transform(HttpRequest httpRequest) {
    var request = new Request(httpRequest);
    var response = new Response(httpRequest.response);
    return new RequestResponsePair(request, response);
  }
}