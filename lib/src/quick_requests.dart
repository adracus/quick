library quick.requests;

import 'dart:io';
import 'dart:mirrors' show reflect;
import 'dart:convert' show JSON;

class Request {
  /** The plain underlying [HttpRequest] of this request. */
  final HttpRequest _request;

  /** The body of this request. May be transformed or set freely. Can be null. */
  var body;

  /** URL parameters of this request. Can be null.
   *
   * The url parameters are set as soon as an url matcher processes a path and
   * are usually set when processed inside a [Handler]. */
  Map<String, String> parameters;

  /** A freely configurable map. Holds additional information for each request. */
  final Map _context = {};

  Request(this._request);

  /** Checks if the given type is accepted by some of the headers. */
  bool accepts(String type) =>
      _request.headers['accept'].any((name) => name.split(',').contains(type));

  /** Checks if any of the content-type headers contains the given type. */
  bool isMime(String type) =>
      _request.headers['content-type'].any((value) => value == type);

  /** Checks if the x-forwarded-host header is not null. */
  bool get isForwarded => _request.headers['x-forwarded-host'] != null;

  /** Gets the value associated with the key in the context of this. */
  operator [](key) => _context[key];

  /** Sets the value with the given key in the context of this. */
  operator []=(key, value) => _context[key] = value;

  /** Retrieves the given header. The name is converted to lower case. */
  List<String> header(String name) => _request.headers[name.toLowerCase()];

  /** Returns the cookies of this request. */
  List<Cookie> get cookies => _request.cookies.map((Cookie cookie) {
        cookie.name = Uri.decodeQueryComponent(cookie.name);
        cookie.value = Uri.decodeQueryComponent(cookie.value);
        return cookie;
      }).toList();

  /** The underlying original [HttpRequest] of this request. */
  HttpRequest get input => _request;

  /** The [HttpSession] of this request. */
  HttpSession get session => _request.session;

  /** The [X509Certificate] of this request. */
  X509Certificate get certificate => _request.certificate;

  /** The requested uri. */
  Uri get uri => _request.uri;

  /** The requested path. */
  String get path => uri.path;

  /** The method of the request. */
  String get method => _request.method;

  /** The query parameters of the request. */
  Map<String, String> get query => uri.queryParameters;

  /** The [HttpHeaders] of this request. */
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

  Response cache(String cacheType, [Map<String, String> options]) {
    if (options == null) {
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
            Uri.encodeQueryComponent(name), Uri.encodeQueryComponent(val)),
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
    Map options = {'expires': 'Thu, 01-Jan-70 00:00:01 GMT', 'path': '/'};
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
