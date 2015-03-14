library quick.router;

import 'dart:async' show runZoned;

import 'quick_requests.dart';
import 'quick_route.dart';
import 'quick_middleware.dart';
import 'quick_handler.dart';

class Router {
  RouteSet routes = new RouteSet();
  MiddlewareList middleware = new MiddlewareList();
  ErrorHandlerList errorHandlers = new ErrorHandlerList();
  
  void handle(Request request, Response response) {
    runZoned(() {
      var handler = routes.matching(request.method, request.path,
          orElse: () => const NonExistentRoute());
      var mLayers = middleware.matching(request.method, request.path);
      var layers = []..addAll(mLayers)..add(handler);
      
      var calls = [];
      for (int i = 0; i < layers.length; i++) {
        calls.add(() {
          var layer = layers[i];
          if (layer is BaseHandler)
            request.parameters = layer.matcher.parameters(request.path);
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
        if (handler is BaseHandler)
          request.parameters = handler.matcher.parameters(request.path);
        handler.handlerFn(error, request, response, () => calls[i + 1]());
      });
    }
    
    calls.first();
  }
}