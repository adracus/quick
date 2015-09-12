library quick.handler;

import 'package:quiver/core.dart';

import 'quick_pattern.dart';

/** An iterable of [Handler]s. */
abstract class HandlerIterable<E extends Handler, F extends Function>
    implements CompositeHandler<E, F> {
  /** Returns the handlers of this iterable. */
  get handlers;

  /** Adds the given [Handler] to this iterable. */
  void add(E handler) {
    handlers.add(handler);
  }

  /** Creates a new [Handler] of type [E] with function [F]. */
  E createHandler(Matcher matcher, F handlerFunction);

  /** Internally creates and adds a new [Handler] from the given parameters. */
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

  void patch(String path, F handler) {
    _addHandler(new MethodSet.patch(), path, handler);
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

  /** Returns a handler matching on [method] and [path]. */
  matching(String method, String path);
}

/** A composite handler with [Handler]s of type [E] and functions of type [F]. */
abstract class CompositeHandler<E extends Handler, F extends Function> {
  /** Adds the given handler to this composite handler. */
  void add(E handler);

  E createHandler(Matcher matcher, F handlerFunction);

  /** Creates and adds a handler that matches on [path] and http verb GET. */
  void get(String path, F handler);

  /** Creates and adds a handler that matches on [path] and http verb POST. */
  void post(String path, F handler);

  /** Creates and adds a handler that matches on [path] and http verb PUT. */
  void put(String path, F handler);

  /** Creates and adds a handler that matches on [path] and http verb PATCH. */
  void patch(String path, F handler);

  /** Creates and adds a handler that matches on [path] and http verb DELETE. */
  void delete(String path, F handler);

  /** Creates and adds a handler that matches on [path] and http verb TRACE. */
  void trace(String path, F handler);

  /** Creates and adds a handler that matches on [path] and http verb HEAD. */
  void head(String path, F handler);

  /** Creates and adds a handler that matches on [path] and http verb CONNECT. */
  void connect(String path, F handler);

  /** Creates and adds a handler that matches on [path] and all http verbs. */
  void all(String path, F handler);

  /** Creates and adds a handler that matches on all requests. */
  void use(F handler);
}

/** A [Handler] that handles with functions of type [F]. */
abstract class Handler<F extends Function> {
  /** The handler function of this handler. */
  F get handlerFn;

  /** Checks whether this handler matches on the given method and path. */
  bool matches(String method, String path);
}

/** A base class for implementing handlers. */
abstract class BaseHandler<F extends Function> implements Handler<F> {
  final Matcher matcher;
  final F handlerFn;

  BaseHandler(this.matcher, this.handlerFn);

  /** Checks whether the underlying matcher matches method and path. */
  bool matches(String method, String path) => matcher.matches(method, path);
}

/** A matcher that matches on a specific method set and url. */
class Matcher {
  /** All http methdos this matcher matches on. */
  final MethodSet methods;

  /** The [Uri]s this matcher matches on. */
  final UrlMatcher matcher;

  /** A matcher that matches on all methods and [Uri]s. */
  Matcher.total()
      : methods = new MethodSet.all(),
        matcher = new UrlMatcher.parse("/.*");

  /** Creates a matcher with the methods and a [UrlMatcher] from the path. */
  Matcher(this.methods, String path) : matcher = new UrlMatcher.parse(path);

  /** Checks whether this matcher matches the given method and path. */
  bool matches(String method, String path) {
    return methods.matches(method) && matcher.matches(path);
  }

  operator ==(other) {
    if (other is! Matcher) return false;
    return methods == other.methods && matcher == other.matcher;
  }

  int get hashCode => hash2(methods, matcher);

  /** Returns all the url parameters that could be extracted from path. */
  Map<String, String> parameters(String path) => matcher.parameters(path);
}

/** A set of http methods / verbs. */
class MethodSet {
  /** A constant list of all possible http methods. */
  static const possibleMethods = const [
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "DELETE",
    "TRACE",
    "CONNECT",
    "PATCH"
  ];

  /** The methods this method set accepts. */
  final Set<String> _methods;

  /** Creates a new method set from the given methods.
   *
   * If an unknown method is contained, this throws a new error with the
   * invalid set. */
  MethodSet(Iterable<String> methods) : _methods = validateMethods(methods);

  /** Creates a new set that matches on all http verbs / methods. */
  MethodSet.all() : _methods = new Set.from(possibleMethods);

  /** Creates a new set that matches on the GET method / verb. */
  MethodSet.get() : _methods = new Set.from(["GET"]);

  /** Creates a new set that matches on the HEAD method / verb. */
  MethodSet.head() : _methods = new Set.from(["HEAD"]);

  /** Creates a new set that matches on the POST method / verb. */
  MethodSet.post() : _methods = new Set.from(["POST"]);

  /** Creates a new set that matches on the PUT method / verb. */
  MethodSet.put() : _methods = new Set.from(["PUT"]);

  /** Creates a new set that matches on the PATCH method / verb. */
  MethodSet.patch() : _methods = new Set.from(["PATCH"]);

  /** Creates a new set that matches on the DELETE method / verb. */
  MethodSet.delete() : _methods = new Set.from(["DELETE"]);

  /** Creates a new set that matches on the TRACE method / verb. */
  MethodSet.trace() : _methods = new Set.from(["TRACE"]);

  /** Creates a new set that matches on the CONNECT method / verb. */
  MethodSet.connect() : _methods = new Set.from(["CONNECT"]);

  /** Checks whether one of this method is the given method. */
  bool matches(String method) {
    return this._methods.contains(method);
  }

  /** Checks if the given set of methods contains an invalid method / verb. */
  static bool validMethodSet(Set<String> methods) {
    return methods.every((method) => possibleMethods.contains(method));
  }

  /** Converts the given iterable to a set and checks if it is invalid.
   *
   * An iterable is considered invalid if it contains invalid methods. All
   * methods are converted to uppercase so case is not important. */
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

/** An exception that is thrown if an invalid set of methods is encountered. */
class InvalidMethodSet implements Exception {
  final Set<String> methods;

  InvalidMethodSet(this.methods);

  toString() => "Invalid method set: ${methods.join(", ")}";
}
