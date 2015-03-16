library quick.requests;

import 'dart:io';
import 'dart:mirrors' show reflect;
import 'dart:convert' show JSON;


class Request {
  final HttpRequest _request;
  var body;
  
  Map<String, String> parameters;
  Map _context = {};
  
  Request(this._request);
  
  bool accepts(String type) =>
      _request.headers['accept'].where((name) =>
          name.split(',').indexOf(type) != -1).isNotEmpty;
  
  bool isMime(String type) =>
      _request.headers['content-type'].where((value) => value == type).isNotEmpty;
  
  bool get isForwarded => _request.headers['x-forwarded-host'] != null;
  
  operator[](key) => _context[key];
  operator[]=(key, value) => _context[key] = value;
  
  List<String> header(String name) => _request.headers[name.toLowerCase()];
  
  List<Cookie> get cookies => _request.cookies.map((Cookie cookie) {
    cookie.name = Uri.decodeQueryComponent(cookie.name);
    cookie.value = Uri.decodeQueryComponent(cookie.value);
    return cookie;
  }).toList();
  
  HttpRequest get input => _request;
  HttpSession get session => _request.session;
  X509Certificate get certificate => _request.certificate;
  Uri get uri => _request.uri;
  String get path => uri.path;
  String get method => _request.method;
  Map<String, String> get query => uri.queryParameters;
  HttpHeaders get headers => _request.headers;
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
    _response.write(message);
    close();
  }
  
  void close() {
    _isSent = true;
    _response.flush().then((_) => _response.close());
  }
  
  header(String name, [value]) {
    if (value == null) {
      _response.headers[name];
    }
    _response.headers.set(name, value);
    return this;
  }
  
  Response add(String content) {
    _response.write(content);
    return this;
  }

  Response get(String name) => header(name);

  Response set(String name, String value) => header(name, value);

  Response type(String contentType) => set('Content-Type', contentType);

  Response cache(String cacheType, [Map<String,String> options]) {
    if(options == null) {
      options = {};
    }
    StringBuffer value = new StringBuffer(cacheType);
    options.forEach((key, val) {
      value.write(', ${key}=${val}');
    });
    return set('Cache-Control', value.toString());
  }

  Response cookie(String name, String val, [Map options]) {
    var cookie = new Cookie(
      Uri.encodeQueryComponent(name),
      Uri.encodeQueryComponent(val)
    ),
    cookieMirror = reflect(cookie);

    if (options != null) {
      options.forEach((option, value) {
        cookieMirror.setField(new Symbol(option), value);
      });
    }

    _response.cookies.add(cookie);
    return this;
  }

  Response deleteCookie(String name) {
    Map options = { 'expires': 'Thu, 01-Jan-70 00:00:01 GMT', 'path': '/' };
    cookie(name, '', options);
    return this;
  }

  void json(data) {
    if (data is Map || data is List) {
      data = JSON.encode(data);
    }
    send(data);
  }

  void jsonp(String name, data) {
    if (data is Map) {
      data = JSON.encode(data);
    }
    send("$name('$data');");
  }

  void redirect(String url, [int code = 302]) {
    _isSent = true;
    _response.statusCode = code;
    header('Location', url);
    _response.close();
  }
}


class RequestRoute {
  final String method;
  final String path;
  
  RequestRoute(this.method, this.path);
}