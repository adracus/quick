library quick.middleware;

import 'quick_requests.dart';
import 'quick_handler.dart';
import 'quick_route.dart';

typedef Next();
typedef MiddlewareHandlerFn(Request request, Response response, Next next);
typedef ErrorHandlerFn(error, Request request, Response response, Next next);

class LogMiddleware implements Middleware {
  MiddlewareHandlerFn get handlerFn => (request, response, next) {
    var time = new DateTime.now();
    print("[$time] ${request.method} ${request.uri}");
    next();
  };
  
  const LogMiddleware();
  
  bool matches(String method, String path) => true;
}

abstract class AlwaysErrorHandler implements ErrorHandler {
  const AlwaysErrorHandler();
  
  bool matches(String method, String path) => true;
}

class RouteNotFoundHandler extends AlwaysErrorHandler {
  ErrorHandlerFn get handlerFn => (error, Request request, Response response, Next next) {
    if (error is RouteNotFound) {
      response.status(404).send("Route not found");
      return;
    }
    next();
  };
  
  const RouteNotFoundHandler();
}

class UncaughtErrorHandler extends AlwaysErrorHandler {
  ErrorHandlerFn get handlerFn => (error, Request request, Response response, Next next) {
    print(error);
    response.status(500).send("Internal server error");
  };
  
  const UncaughtErrorHandler();
}


class MiddlewareList extends Object with HandlerIterable<Middleware, MiddlewareHandlerFn> {
  List<Middleware> handlers = [];
      
  MiddlewareList();
  
  BaseMiddleware createHandler(HandlerMatcher matcher, MiddlewareHandlerFn handler) {
    return new BaseMiddleware(matcher, handler);
  }
  
  List<Middleware> matching(String method, String path) {
    return handlers.where((middleware) =>
        middleware.matches(method, path))
                  .toList();
  }
}

class ErrorHandlerList extends Object with HandlerIterable<ErrorHandler, ErrorHandlerFn> {
  List<ErrorHandler> handlers = [];
  
  ErrorHandlerList();
  
  BaseErrorHandler createHandler(HandlerMatcher matcher, ErrorHandlerFn handler) {
    return new BaseErrorHandler(matcher, handler);
  }
  
  List<ErrorHandler> matching(String method, String path) {
    return handlers.where((handler) =>
        handler.matches(method, path))
                       .toList();
  }
}

class BaseMiddleware extends BaseHandler<MiddlewareHandlerFn> implements Middleware {
  BaseMiddleware(HandlerMatcher matcher, MiddlewareHandlerFn handlerFn)
      : super(matcher, handlerFn);
}

class BaseErrorHandler extends BaseHandler<ErrorHandlerFn> implements ErrorHandler {
  BaseErrorHandler(HandlerMatcher matcher, ErrorHandlerFn handlerFn)
      : super(matcher, handlerFn);
}

abstract class ErrorHandler implements Handler<ErrorHandlerFn> {
  bool matches(String method, String path) => true;
}

abstract class Middleware implements Handler<MiddlewareHandlerFn> {
}