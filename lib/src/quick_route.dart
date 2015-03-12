library quick.route;

import 'package:quiver/core.dart';

import 'quick_requests.dart';
import 'quick_pattern.dart';

typedef Next();
typedef Middleware(Request request, Response response, Next next);
typedef Handler(Request request, Response response);


class Router {
  Map<String, dynamic> _handlers = {};
  
  Router();
}


class Route {
  final RouteMatcher matcher;
  final Handler handler;
  
  Route(this.matcher, this.handler);
  
  operator==(other) {
    if (other is! Route) return false;
    return matcher == other.matcher;
  }
}


class RouteMatcher {
  final MethodSet methods;
  final UrlMatcher matcher;
  
  RouteMatcher(this.methods, this.matcher);
  
  bool matches(String method, String path) {
    return methods.matches(method) && matcher.matches(path);
  }
  
  operator==(other) {
    if (other is! RouteMatcher) return false;
    return methods == other.methods && matcher == other.matcher;
  }
  
  int get hashCode => hash2(methods, matcher);
}


class MethodSet {
  static const possibleMethods =
      const["GET", "HEAD", "POST", "PUT", "DELETE", "TRACE", "CONNECT"];
  
  final Set<String> _methods;
  
  MethodSet(Iterable<String> methods)
      : _methods = validateMethods(methods);
  
  MethodSet.get()
      : _methods = new Set.from(["GET"]);
  
  MethodSet.head()
      : _methods = new Set.from(["HEAD"]);
  
  MethodSet.post()
      : _methods = new Set.from(["POST"]);
  
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