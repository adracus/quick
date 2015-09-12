library quick.router;

import 'dart:async' show runZoned;

import 'quick_requests.dart';
import 'quick_route.dart';
import 'quick_middleware.dart';
import 'quick_handler.dart';

class Router implements CompositeHandler {
  /** Routes of this router.
   *
   * Routes are [Handler]s that take a request, accept it and send a response.*/
  final RouteSet routes = new RouteSet();

  /** Middleware of this router.
   *
   * Middlewares are [Handler]s that take requests, transform them and either
   * accept them and send a response, reject them or pass it to the next
   * [Handler]. */
  final MiddlewareList middleware = new MiddlewareList();

  /** Error handlers are [Handler]s that are called when errors occured.
   *
   * An error handler can decide whether it matches an error, can process it
   * or hand it over to the next error handler. */
  final ErrorHandlerList errorHandlers = new ErrorHandlerList();

  /** Creates a handler with the given [Matcher] and handler function.
   *
   * If the handler function is a [RouteHandlerFn], a [BaseRoute] is returned.
   * If the handler function is a [MiddlewareHandlerFn], a [BaseMiddleware] is
   * returned.
   * If the handler function is an [ErrorHandlerFn], a [BaseErrorHandler] is
   * returned.
   * If the given function matches none of the mentioned signatures, an
   * [ArgumentError] is thrown. */
  createHandler(Matcher matcher, Function handlerFn) {
    if (handlerFn is RouteHandlerFn) return new BaseRoute(matcher, handlerFn);
    if (handlerFn
        is MiddlewareHandlerFn) return new BaseMiddleware(matcher, handlerFn);
    if (handlerFn
        is ErrorHandlerFn) return new BaseErrorHandler(matcher, handlerFn);
    throw new ArgumentError.value(
        handlerFn, "handlerFn", "Invalid handler function");
  }

  /** Internally creates a matcher and adds it to its handler list. */
  void _addHandler(MethodSet methods, String path, Function handlerFn) {
    var matcher = new Matcher(methods, path);
    var handler = createHandler(matcher, handlerFn);
    add(handler);
  }

  /** Adds the given [Handler].
   *
   * The handler has to be either a [Route], [Middleware] or [ErrorHandler],
   * otherwise an [ArgumentError] will be thrown. */
  void add(Handler handler) {
    if (handler is Route) {
      routes.add(handler);
      return;
    }
    if (handler is Middleware) {
      middleware.add(handler);
      return;
    }
    if (handler is ErrorHandler) {
      errorHandlers.add(handler);
      return;
    }
    throw new ArgumentError.value(handler, "handler", "Invalid handler");
  }

  /** Registers a new handler on GET requests on the specified path. */
  void get(String path, Function handler) {
    _addHandler(new MethodSet.get(), path, handler);
  }

  /** Registers a new handler on POST requests on the specified path. */
  void post(String path, Function handler) {
    _addHandler(new MethodSet.post(), path, handler);
  }

  /** Registers a new handler on PUT requests on the specified path. */
  void put(String path, Function handler) {
    _addHandler(new MethodSet.put(), path, handler);
  }

  /** Registers a new handler on PATCH requests on the specified path. */
  void patch(String path, Function handler) {
    _addHandler(new MethodSet.patch(), path, handler);
  }

  /** Registers a new handler on DELETE requests on the specified path. */
  void delete(String path, Function handler) {
    _addHandler(new MethodSet.delete(), path, handler);
  }

  /** Registers a new handler on TRACE requests on the specified path. */
  void trace(String path, Function handler) {
    _addHandler(new MethodSet.trace(), path, handler);
  }

  /** Registers a new handler on HEAD requests on the specified path. */
  void head(String path, Function handler) {
    _addHandler(new MethodSet.head(), path, handler);
  }

  /** Registers a new handler on CONNECT requests on the specified path. */
  void connect(String path, Function handler) {
    _addHandler(new MethodSet.connect(), path, handler);
  }

  /** Registers a new handler on all requests on the specified path. */
  void all(String path, Function handler) {
    _addHandler(new MethodSet.all(), path, handler);
  }

  /** Registers a new handler on all methods and on all paths. */
  void use(Function handler) {
    _addHandler(new MethodSet.all(), "/.*", handler);
  }

  /** Handles the given [Request] and [Response] using routes and middleware. */
  void handle(Request request, Response response) {
    runZoned(() {
      var handler = routes.matching(request.method, request.path,
          orElse: () => const NonExistentRoute());
      var mLayers = middleware.matching(request.method, request.path);
      var layers = []
        ..addAll(mLayers)
        ..add(handler);

      var calls = [];
      for (int i = 0; i < layers.length; i++) {
        calls.add(() {
          var layer = layers[i];
          if (layer is BaseHandler) request.parameters =
              layer.matcher.parameters(request.path);
          if (layer is Middleware) {
            layer.handlerFn(request, response, () => calls[i + 1]());
            return;
          }
          if (layer is Route) {
            layer.handlerFn(request, response);
          }
        });
      }
      calls.first(); // Run the pipeline
    }, onError: (error) => handleError(error, request, response));
  }

  /** Handles the given error that occured during the specified [Request]. */
  void handleError(error, Request request, Response response) {
    var handlers = errorHandlers.matching(request.method, request.path);
    if (handlers.isEmpty) throw error;

    var calls = [];
    for (int i = 0; i < handlers.length; i++) {
      calls.add(() {
        var handler = handlers[i];
        if (handler is BaseHandler) request.parameters =
            handler.matcher.parameters(request.path);
        handler.handlerFn(error, request, response, () {
          if (i ==
              handlers.length - 1) throw error; // Last handler, uncaught error
          calls[i + 1]();
        });
      });
    }

    calls.first();
  }
}
