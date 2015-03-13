library quick.route;

import 'dart:async' show runZoned;

import 'package:quiver/core.dart';

import 'quick_requests.dart';
import 'quick_pattern.dart';

typedef Next();
typedef MiddlewareHandlerFn(Request request, Response response, Next next);
typedef ErrorHandlerFn(error, Request request, Response response, Next next);
typedef RouteHandlerFn(Request request, Response response);


class Router {
  RouteSet routes = new RouteSet();
  MiddlewareList middleware = new MiddlewareList();
  ErrorHandlerList errorHandlers = new ErrorHandlerList();
  
  void handle(Request request, Response response) {
    var handler = routes.matching(request.method, request.path);
    var mLayers = middleware.matching(request.method, request.path);
    var layers = []..addAll(mLayers)..add(handler);
    
    var calls = [];
    for (int i = 0; i < layers.length; i++) {
      calls.add(() {
        var layer = layers[i];
        request.parameters = layer.matcher.parameters(request.path);
        if (layer is Middleware) {
          layer.handle(request, response, () => calls[i + 1]());
          return;
        }
        if (layer is Route) {
          layer.handle(request, response);
        }
      });
    }
    
    runZoned(() {
      calls.first(); // Run the pipeline
    }, onError: (error) => handleError(error, request, response));
  }
  
  void handleError(error, Request request, Response response) {
    var handlers = errorHandlers.matching(request.method, request.path);
    if (handlers.isEmpty) throw error;
    
    var calls = [];
    for (int i = 0; i < handlers.length; i++) {
      calls.add(() {
        var handler = handlers[i];
        request.parameters = handler.matcher.parameters(request.path);
        handler.handle(error, request, response, () => calls[i + 1]());
      });
    }
    
    calls.first();
  }
}


abstract class HandlerIterable<E, F> {
  get _handlers;
  
  E _createHandler(RouteMatcher matcher, F handlerFunction);
  
  void _addHandler(MethodSet methods, String path, F handlerFunction) {
    var matcher = new RouteMatcher(methods, path);
    var handler = _createHandler(matcher, handlerFunction);
    _handlers.add(handler);
  }
  
  void get(String path, F handler) {
    _addHandler(new MethodSet.get(), path, handler);
  }
  
  void post(String path, F handler) {
    _addHandler(new MethodSet.post(), path, handler);
  }
  
  void put(String path, F handler) {
    _addHandler(new MethodSet.put(), path, handler);
  }
  
  void delete(String path, F handler) {
    _addHandler(new MethodSet.delete(), path, handler);
  }
  
  void trace(String path, F handler) {
    _addHandler(new MethodSet.trace(), path, handler);
  }
  
  void head(String path, F handler) {
    _addHandler(new MethodSet.head(), path, handler);
  }
  
  void connect(String path, F handler) {
    _addHandler(new MethodSet.connect(), path, handler);
  }
  
  void all(String path, F handler) {
    _addHandler(new MethodSet.all(), path, handler);
  }
  
  void use(F handler) {
    _addHandler(new MethodSet.all(), "/.*", handler);
  }
  
  matching(String method, String path);
}


class RouteSet extends Object with HandlerIterable<Route, RouteHandlerFn> {
  Set<Route> _handlers = new Set();
    
  RouteSet();
  
  Route _createHandler(RouteMatcher matcher, RouteHandlerFn handler) {
    return new Route(matcher, handler);
  }
  
  Route matching(String method, String path) {
    return _handlers.firstWhere((route) => route.matches(method, path));
  }
}


class MiddlewareList extends Object with HandlerIterable<Middleware, MiddlewareHandlerFn> {
  List<Middleware> _handlers = [];
      
  MiddlewareList();
  
  Middleware _createHandler(RouteMatcher matcher, MiddlewareHandlerFn handler) {
    return new Middleware(matcher, handler);
  }
  
  List<Middleware> matching(String method, String path) {
    return _handlers.where((middleware) =>
        middleware.matches(method, path))
                       .toList();
  }
}

class ErrorHandlerList extends Object with HandlerIterable<ErrorHandler, ErrorHandlerFn> {
  List<ErrorHandler> _handlers = [];
  
  ErrorHandlerList();
  
  ErrorHandler _createHandler(RouteMatcher matcher, ErrorHandlerFn handler) {
    return new ErrorHandler(matcher, handler);
  }
  
  List<ErrorHandler> matching(String method, String path) {
    return _handlers.where((handler) =>
        handler.matches(method, path))
                       .toList();
  }
}

abstract class Handler<F> {
  final RouteMatcher matcher;
  final F handlerFn;
  
  Handler(this.matcher, this.handlerFn);
  
  bool matches(String method, String path) => matcher.matches(method, path);
}


class ErrorHandler extends Handler<ErrorHandlerFn>{
  ErrorHandler(RouteMatcher matcher, ErrorHandlerFn errorHandlerFn)
      : super(matcher, errorHandlerFn);
  
  void handle(error, Request request, Response response, Next next) =>
      handlerFn(error, request, response, next);
}


class Middleware extends Handler<MiddlewareHandlerFn> {
  Middleware(RouteMatcher matcher, MiddlewareHandlerFn handler)
      : super(matcher, handler);
  
  void handle(Request request, Response response, Next next) =>
      handlerFn(request, response, next);
}


class Route extends Handler<RouteHandlerFn> {
  Route(RouteMatcher matcher, RouteHandlerFn handler)
      : super(matcher, handler);
  
  operator==(other) {
    if (other is! Route) return false;
    return matcher == other.matcher;
  }

  int get hashCode => matcher.hashCode;
  
  void handle(Request request, Response response) {
    handlerFn(request, response);
  }
}


class RouteMatcher {
  final MethodSet methods;
  final UrlMatcher matcher;
  
  RouteMatcher(this.methods, String path)
      : matcher = new UrlMatcher.parse(path);
  
  bool matches(String method, String path) {
    return methods.matches(method) && matcher.matches(path);
  }
  
  operator==(other) {
    if (other is! RouteMatcher) return false;
    return methods == other.methods && matcher == other.matcher;
  }
  
  int get hashCode => hash2(methods, matcher);
  
  Map<String, String> parameters(String path) => matcher.parameters(path);
}


class MethodSet {
  static const possibleMethods =
      const["GET", "HEAD", "POST", "PUT", "DELETE", "TRACE", "CONNECT"];
  
  final Set<String> _methods;
  
  MethodSet(Iterable<String> methods)
      : _methods = validateMethods(methods);
  
  MethodSet.all()
      : _methods = new Set.from(possibleMethods);
  
  MethodSet.get()
      : _methods = new Set.from(["GET"]);
  
  MethodSet.head()
      : _methods = new Set.from(["HEAD"]);
  
  MethodSet.post()
      : _methods = new Set.from(["POST"]);
  
  MethodSet.put()
      : _methods = new Set.from(["PUT"]);
  
  MethodSet.delete()
      : _methods = new Set.from(["DELETE"]);
  
  MethodSet.trace()
      : _methods = new Set.from(["TRACE"]);
  
  MethodSet.connect()
      : _methods = new Set.from(["CONNECT"]);
  
  bool matches(String method) {
    return this._methods.contains(method);
  }
  
  static bool validMethodSet(Set<String> methods) {
    return methods.every((method) => possibleMethods.contains(method));
  }
  
  static Set<String> validateMethods(Iterable<String> methods) {
    var uniform = methods.map((method) => method.toUpperCase()).toSet();
    if (!validMethodSet(uniform)) throw new InvalidMethodSet(uniform);
    return uniform;
  }
  
  operator==(other) {
    if (other is! MethodSet) return false;
    return this._methods.difference(other._methods).isEmpty;
  }
  
  int get hashCode {
    return hashObjects(this._methods.toList()..sort());
  }
}

class InvalidMethodSet implements Exception {
  final Set<String> methods;
  
  InvalidMethodSet(this.methods);
  
  toString() => "Invalid method set: ${methods.join(", ")}";
}