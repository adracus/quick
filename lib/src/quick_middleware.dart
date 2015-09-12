library quick.middleware;

import 'dart:async' show Future, runZoned;
import 'dart:convert' show JSON;
import 'dart:io' show HttpStatus;

import 'quick_requests.dart';
import 'quick_handler.dart';
import 'quick_route.dart';

/** The next function for middlewares or error handlers. */
typedef Next();

/** The signature for middleware functions. */
typedef MiddlewareHandlerFn(Request request, Response response, Next next);

/** The signature for error handler functions. */
typedef ErrorHandlerFn(error, Request request, Response response, Next next);

/** Parses and sets the body of a request. */
abstract class BodyParser implements Middleware {
  /** The function that runs if the parsing errors. */
  ErrorHandlerFn onError;

  /** Parses and sets the body. */
  MiddlewareHandlerFn get handlerFn =>
      (Request request, Response response, Next next) {
        if (shouldApply(request)) {
          return runZoned(() {
            return apply(request).then((result) {
              request.body = result;
              return next();
            });
          }, onError: (e) {
            if (null != onError) return onError(e, request, response, next);
            throw e;
          });
        }
        return next();
      };

  /** A body parser that parses the request as json and sets the body. */
  factory BodyParser.json() => new JsonBodyParser();

  /** A body parser that parses the request as text and sets the body. */
  factory BodyParser.text() => new TextBodyParser();

  /** A body parser that parses the request as urlencoded and sets the body. */
  factory BodyParser.urlEncoded() => new UrlEncodedBodyParser();

  /** Applies the parsing to the given request. */
  Future apply(Request request);

  /** Checks whether the parsing should be applied to the given request. */
  bool shouldApply(Request request);

  /** Always true for a body parser. */
  bool matches(String method, String path) => true;
}

/** A body parser that parses the incoming payload as text. */
class TextBodyParser extends Object with BodyParser {
  TextBodyParser();

  bool shouldApply(Request request) => request.headers.contentLength != null &&
      request.headers.contentLength != 0;

  Future<String> apply(Request request) {
    return request.input.toList().then((lineBytes) {
      return lineBytes.fold("",
          (result, line) => result += new String.fromCharCodes(line) + "\n");
    });
  }
}

/** A body parser that parses the incoming payload as json. */
class JsonBodyParser extends Object with BodyParser {
  static final defaultOnError = (e, request, response, next) {
    response.status(HttpStatus.BAD_REQUEST).send("Invalid JSON");
  };

  JsonBodyParser({ErrorHandlerFn onError}) {
    this.onError = null == onError ? defaultOnError : onError;
  }

  TextBodyParser _parser = new TextBodyParser();

  bool shouldApply(Request request) {
    return _parser.shouldApply(request) &&
        request.headers.contentType != null &&
        request.headers.contentType.primaryType == "application" &&
        request.headers.contentType.subType == "json";
  }

  Future apply(Request request) {
    return _parser.apply(request).then((text) {
      return JSON.decode(text);
    });
  }
}

/** A body parser that parses the incoming payload as urlencoded. */
class UrlEncodedBodyParser extends Object with BodyParser {
  static final ErrorHandlerFn defaultOnError =
      (error, request, response, next) {
    response.status(HttpStatus.BAD_REQUEST).send("Invalid urlencoded body");
  };

  TextBodyParser _parser = new TextBodyParser();

  bool shouldApply(Request request) {
    return _parser.shouldApply(request) &&
        request.headers.contentType != null &&
        request.headers.contentType.primaryType == "application" &&
        request.headers.contentType.subType == "x-www-form-urlencoded";
  }

  Future apply(Request request) {
    return _parser.apply(request).then((text) {
      return Uri.splitQueryString(text);
    });
  }
}

/** A middleware that logs time, method and uri for each request. */
class LogMiddleware implements Middleware {
  MiddlewareHandlerFn get handlerFn => (request, response, next) {
        var time = new DateTime.now();
        print("[$time] ${request.method} ${request.uri}");
        next();
      };

  const LogMiddleware();

  bool matches(String method, String path) => true;
}

/** An error handler that always handles. */
abstract class AlwaysErrorHandler implements ErrorHandler {
  const AlwaysErrorHandler();

  bool matches(String method, String path) => true;
}

/** An error handler that returns 404 if a route was not found. */
class RouteNotFoundHandler extends AlwaysErrorHandler {
  ErrorHandlerFn get handlerFn =>
      (error, Request request, Response response, Next next) {
        if (error is RouteNotFound) {
          response.status(404).send("Route not found");
          return;
        }
        next();
      };

  const RouteNotFoundHandler();
}

/** An error handler that sends 500 server error. */
class UncaughtErrorHandler extends AlwaysErrorHandler {
  ErrorHandlerFn get handlerFn =>
      (error, Request request, Response response, Next next) {
        print(error);
        try {
          if (!response.isSent) response
              .status(500)
              .send("Internal server error");
        } catch (e) {
          print(e);
        }
      };

  const UncaughtErrorHandler();
}

/** List of middlewares. */
class MiddlewareList extends Object
    with HandlerIterable<Middleware, MiddlewareHandlerFn> {
  final List<Middleware> handlers = [];

  MiddlewareList();

  BaseMiddleware createHandler(Matcher matcher, MiddlewareHandlerFn handler) {
    return new BaseMiddleware(matcher, handler);
  }

  List<Middleware> matching(String method, String path) {
    return handlers
        .where((middleware) => middleware.matches(method, path))
        .toList();
  }
}

/** A list of error handlers. */
class ErrorHandlerList extends Object
    with HandlerIterable<ErrorHandler, ErrorHandlerFn> {
  final List<ErrorHandler> handlers = [];

  ErrorHandlerList();

  BaseErrorHandler createHandler(Matcher matcher, ErrorHandlerFn handler) {
    return new BaseErrorHandler(matcher, handler);
  }

  List<ErrorHandler> matching(String method, String path) {
    return handlers.where((handler) => handler.matches(method, path)).toList();
  }
}

class BaseMiddleware extends BaseHandler<MiddlewareHandlerFn>
    implements Middleware {
  BaseMiddleware(Matcher matcher, MiddlewareHandlerFn handlerFn)
      : super(matcher, handlerFn);
}

class BaseErrorHandler extends BaseHandler<ErrorHandlerFn>
    implements ErrorHandler {
  BaseErrorHandler(Matcher matcher, ErrorHandlerFn handlerFn)
      : super(matcher, handlerFn);
}

abstract class ErrorHandler implements Handler<ErrorHandlerFn> {
  bool matches(String method, String path) => true;
}

abstract class Middleware implements Handler<MiddlewareHandlerFn> {}
