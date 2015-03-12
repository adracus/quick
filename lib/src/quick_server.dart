library quick.server;

import 'dart:io';

import 'quick_route.dart';


class Server {
  Router router;
  
  static void listen({int port: 8080, String address: "0.0.0.0"}) {
    HttpServer.bind(address, port).then((server) {
      
      server.listen((request) {
        request.response.write("hello");
        request.response.close();
      });
    });
  }
}