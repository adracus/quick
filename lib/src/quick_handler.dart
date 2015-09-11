library quick.handler;

import 'package:quiver/core.dart';

import 'quick_pattern.dart';

abstract class HandlerIterable<E extends Handler, F extends Function>
    implements CompositeHandler<E, F> {
  get handlers;

  void add(E handler) {
    handlers.add(handler);
  }

  E createHandler(Matcher matcher, F handlerFunction);

  void _addHandler(MethodSet methods, String path, F handlerFunction) {
    var matcher = new Matcher(methods, path);
    var handler = createHandler(matcher, handlerFunction);
    add(handler);
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

abstract class CompositeHandler<E extends Handler, F extends Function> {
  void add(E handler);

  E createHandler(Matcher matcher, F handlerFunction);

  void get(String path, F handler);

  void post(String path, F handler);

  void put(String path, F handler);

  void delete(String path, F handler);

  void trace(String path, F handler);

  void head(String path, F handler);

  void connect(String path, F handler);

  void all(String path, F handler);

  void use(F handler);
}

abstract class Handler<F extends Function> {
  F get handlerFn;

  bool matches(String method, String path);
}

abstract class BaseHandler<F extends Function> implements Handler<F> {
  final Matcher matcher;
  final F handlerFn;

  BaseHandler(this.matcher, this.handlerFn);

  bool matches(String method, String path) => matcher.matches(method, path);
}

class Matcher {
  final MethodSet methods;
  final UrlMatcher matcher;

  Matcher.total()
      : methods = new MethodSet.all(),
        matcher = new UrlMatcher.parse("/.*");

  Matcher(this.methods, String path) : matcher = new UrlMatcher.parse(path);

  bool matches(String method, String path) {
    return methods.matches(method) && matcher.matches(path);
  }

  operator ==(other) {
    if (other is! Matcher) return false;
    return methods == other.methods && matcher == other.matcher;
  }

  int get hashCode => hash2(methods, matcher);

  Map<String, String> parameters(String path) => matcher.parameters(path);
}

class MethodSet {
  static const possibleMethods = const [
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "DELETE",
    "TRACE",
    "CONNECT"
  ];

  final Set<String> _methods;

  MethodSet(Iterable<String> methods) : _methods = validateMethods(methods);

  MethodSet.all() : _methods = new Set.from(possibleMethods);

  MethodSet.get() : _methods = new Set.from(["GET"]);

  MethodSet.head() : _methods = new Set.from(["HEAD"]);

  MethodSet.post() : _methods = new Set.from(["POST"]);

  MethodSet.put() : _methods = new Set.from(["PUT"]);

  MethodSet.delete() : _methods = new Set.from(["DELETE"]);

  MethodSet.trace() : _methods = new Set.from(["TRACE"]);

  MethodSet.connect() : _methods = new Set.from(["CONNECT"]);

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

  operator ==(other) {
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
