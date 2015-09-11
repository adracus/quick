library quick.router;

import 'dart:async' show runZoned;

import 'quick_requests.dart';
import 'quick_route.dart';
import 'quick_middleware.dart';
import 'quick_handler.dart';

class Router implements CompositeHandler {
  RouteSet routes = new RouteSet();
  MiddlewareList middleware = new MiddlewareList();
  ErrorHandlerList errorHandlers = new ErrorHandlerList();

  createHandler(Matcher matcher, Function handlerFn) {
    if (handlerFn is RouteHandlerFn) return new BaseRoute(matcher, handlerFn);
    if (handlerFn
        is MiddlewareHandlerFn) return new BaseMiddleware(matcher, handlerFn);
    if (handlerFn
        is ErrorHandlerFn) return new BaseErrorHandler(matcher, handlerFn);
    throw new ArgumentError.value(
        handlerFn, "handlerFn", "Invalid handler function");
  }

  void _addHandler(MethodSet methods, String path, Function handlerFn) {
    var matcher = new Matcher(methods, path);
    var handler = createHandler(matcher, handlerFn);
    add(handler);
  }

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

  void get(String path, Function handler) {
    _addHandler(new MethodSet.get(), path, handler);
  }

  void post(String path, Function handler) {
    _addHandler(new MethodSet.post(), path, handler);
  }

  void put(String path, Function handler) {
    _addHandler(new MethodSet.put(), path, handler);
  }

  void delete(String path, Function handler) {
    _addHandler(new MethodSet.delete(), path, handler);
  }

  void trace(String path, Function handler) {
    _addHandler(new MethodSet.trace(), path, handler);
  }

  void head(String path, Function handler) {
    _addHandler(new MethodSet.head(), path, handler);
  }

  void connect(String path, Function handler) {
    _addHandler(new MethodSet.connect(), path, handler);
  }

  void all(String path, Function handler) {
    _addHandler(new MethodSet.all(), path, handler);
  }

  void use(Function handler) {
    _addHandler(new MethodSet.all(), "/.*", handler);
  }

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
