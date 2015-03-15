library quick.middleware;

import 'dart:async' show Future;
import 'dart:convert' show JSON;
import 'dart:io' show ContentType;

import 'quick_requests.dart';
import 'quick_handler.dart';
import 'quick_route.dart';

typedef Next();
typedef MiddlewareHandlerFn(Request request, Response response, Next next);
typedef ErrorHandlerFn(error, Request request, Response response, Next next);

abstract class BodyParser implements Middleware {
  MiddlewareHandlerFn get handlerFn => (Request request, Response response, Next next) {
    if (shouldApply(request)) {
      return apply(request).then((result) {
        request.body = result;
        return next();
      });
    }
    return next();
  };
  
  factory BodyParser.json() => new JsonBodyParser();
  factory BodyParser.text() => new TextBodyParser();
  
  Future apply(Request request);
  
  bool shouldApply(Request request);
  
  bool matches(String method, String path) => true;
}

class TextBodyParser extends Object with BodyParser {
  shouldApply(Request request) => request.headers.contentLength != 0;
  
  Future<String> apply(Request request) {
    return request.request.toList().then((lineBytes) {
      return lineBytes.fold("", (result, line) =>
          result += new String.fromCharCodes(line) + "\n");
    });
  }
}

class JsonBodyParser extends Object with BodyParser {
  TextBodyParser _parser = new TextBodyParser();
  
  bool shouldApply(Request request) {
    return _parser.shouldApply(request) &&
        request.headers.contentType.primaryType == "application" &&
        request.headers.contentType.subType == "json";
  }
  
  Future apply(Request request) {
    return _parser.apply(request).then((text) {
      return JSON.decode(text);
    });
  }
}

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
    try {
      if (!response.isSent)
        response.status(500).send("Internal server error");
    } catch (e) {
      print(e);
    }
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