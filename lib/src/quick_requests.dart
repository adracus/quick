library quick.requests;

import 'dart:io' show HttpResponse, HttpRequest;


class Request {
  final HttpRequest _request;
  var body;
  
  Map<String, String> parameters;
  Map _context = {};
  
  Request(this._request);
  
  operator[](key) => _context[key];
  operator[]=(key, value) => _context[key] = value;
  
  Uri get uri => _request.uri;
  String get path => uri.path;
  String get method => _request.method;
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