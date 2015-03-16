library quick.route;

import 'quick_requests.dart';
import 'quick_handler.dart';

typedef RouteHandlerFn(Request request, Response response);


class RouteNotFound implements Exception {
  final Uri uri;
  
  RouteNotFound(this.uri);
  
  toString() => "Could not find $uri";
}


class NonExistentRoute implements Route {
  RouteHandlerFn get handlerFn => (Request request, Response response) {
    throw new RouteNotFound(request.uri);
  };
  
  const NonExistentRoute();
  
  bool matches(String method, String path) => true;
}


class RouteSet extends Object with HandlerIterable<Route, RouteHandlerFn> {
  Set<Route> handlers = new Set();
    
  RouteSet();
  
  BaseRoute createHandler(Matcher matcher, RouteHandlerFn handler) {
    return new BaseRoute(matcher, handler);
  }
  
  Route matching(String method, String path, {Route orElse()}) {
    return handlers.firstWhere((route) => route.matches(method, path),
        orElse: orElse);
  }
}

class BaseRoute extends BaseHandler<RouteHandlerFn> implements Route {
  BaseRoute(Matcher matcher, RouteHandlerFn handlerFn)
      : super(matcher, handlerFn);
  
  operator==(other) {
    if (other is! BaseRoute) return false;
    return matcher == other.matcher;
  }
  
  int get hashCode => matcher.hashCode;
}


abstract class Route implements Handler<RouteHandlerFn> {
}