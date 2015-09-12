library quick.route;

import 'quick_requests.dart';
import 'quick_handler.dart';

typedef RouteHandlerFn(Request request, Response response);

/** Exception that is thrown if no [Handler] is found for a specific [Uri]. */
class RouteNotFound implements Exception {
  /** Uri on which no [Handler] could be found. */
  final Uri uri;

  /** Creates a new exception that no route was found for the given [Uri]. */
  RouteNotFound(this.uri);

  toString() => "Could not find $uri";
}

/** Route handler for non existing routes. */
class NonExistentRoute implements Route {
  /** The handler function. */
  RouteHandlerFn get handlerFn => (Request request, Response response) {
        throw new RouteNotFound(request.uri);
      };

  /** Creates a new non existent route handler. */
  const NonExistentRoute();

  /** Matches on all methods and paths. */
  bool matches(String method, String path) => true;
}

/** A set of routes. */
class RouteSet extends Object with HandlerIterable<Route, RouteHandlerFn> {
  final Set<Route> handlers = new Set();

  /** Creates a new set of routes. */
  RouteSet();

  /** Creates a new [BaseRoute] handler from a given matcher and function. */
  BaseRoute createHandler(Matcher matcher, RouteHandlerFn handler) {
    return new BaseRoute(matcher, handler);
  }

  /** Checks if there is a route matching on [method] and [path].
   *
   * Checks if there is a route matching on [method] and [path].
   * If no route matches, the result of [orElse] is returned. */
  Route matching(String method, String path, {Route orElse()}) {
    return handlers.firstWhere((route) => route.matches(method, path),
        orElse: orElse);
  }
}

/** A basic route that implements [Route] with a given handler function. */
class BaseRoute extends BaseHandler<RouteHandlerFn> implements Route {
  BaseRoute(Matcher matcher, RouteHandlerFn handlerFn)
      : super(matcher, handlerFn);

  operator ==(other) {
    if (other is! BaseRoute) return false;
    return matcher == other.matcher;
  }

  int get hashCode => matcher.hashCode;
}

/** A [Handler] that handles a route on a specific path and http verb. */
abstract class Route implements Handler<RouteHandlerFn> {}
