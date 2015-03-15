library quick.requests;

import 'dart:io' show HttpResponse, HttpRequest, HttpHeaders;


class Request {
  final HttpRequest request;
  var body;
  
  Map<String, String> parameters;
  Map _context = {};
  
  Request(this.request);
  
  operator[](key) => _context[key];
  operator[]=(key, value) => _context[key] = value;
  
  Uri get uri => request.uri;
  String get path => uri.path;
  String get method => request.method;
  Map<String, String> get query => uri.queryParameters;
  HttpHeaders get headers => request.headers;
}

class Response {
  final HttpResponse _response;
  bool _isSent = false;
  
  Response(this._response);
  
  Response status(int code) {
    _response.statusCode = code;
    return this;
  }
  
  bool get isSent => _isSent;
  
  void send(String message) {
    _isSent = true;
    _response.write(message);
    _response.flush().then((_) => _response.close());
  }
}


class RequestRoute {
  final String method;
  final String path;
  
  RequestRoute(this.method, this.path);
}