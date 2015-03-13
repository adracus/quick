library quick.requests;

import 'dart:io' show HttpResponse;

import 'quick_route.dart';


class Request {
  final String method;
  final Uri uri;
  String body;
  
  Map<String, String> parameters;
  Map context = {};
  
  Request(this.method, this.uri, [this.body]);
  
  String get path => uri.path;
  Map<String, String> get query => uri.queryParameters;
}

class Response {
  final HttpResponse _response;
  
  Response(this._response);
  
  Response status(int code) {
    _response.statusCode = code;
    return this;
  }
  
  void send(String message) {
    _response.write(message);
    _response.flush().then((_) => _response.close());
  }
}


class RequestRoute {
  final String method;
  final String path;
  
  RequestRoute(this.method, this.path);
}