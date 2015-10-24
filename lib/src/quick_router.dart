library quick.router;

import 'dart:async' show Stream, Future, StreamController, StreamTransformer;
import 'dart:convert' show JSON;

import 'quick_server.dart';
import 'quick_pattern.dart' show UrlMatcher;

typedef Stream<Context> TransformFunction(Stream<Context> requests);
typedef void ErrorHandler(error);
typedef void ConsumeFunction(Context ctx);
typedef bool ErrorMatcher(error);

abstract class Directive {
  bool matches(Context ctx);

  Stream<Context> handle(Stream<Context> requests);

  factory Directive(TransformFunction transform) {
    return new TransformDirective(transform);
  }

  HorizontalCompositeDirective operator %(Directive that) => horizontal(that);

  HorizontalCompositeDirective horizontal(Directive other) =>
      HorizontalCompositeDirective.merge(this, other);

  VerticalCompositeDirective get get => method("get");
  VerticalCompositeDirective get post => method("post");
  VerticalCompositeDirective get put => method("put");
  VerticalCompositeDirective get delete => method("delete");
  VerticalCompositeDirective get patch => method("patch");

  VerticalCompositeDirective get logRoute => vertical(new LogDirective());

  VerticalCompositeDirective path(String path) =>
      vertical(new PathDirective(path));

  VerticalCompositeDirective method(String name) =>
      vertical(new MethodDirective(name));

  VerticalCompositeDirective listen(ConsumeFunction consume) =>
      vertical(new ConsumeDirective(consume));

  ErrorHandlerDirective handleError(void onError(error), {bool test(error)}) =>
      new ErrorHandlerDirective(this, onError, matcher: test);

  VerticalCompositeDirective transform(TransformFunction transform) =>
      vertical(new HandleDirective(transform));

  VerticalCompositeDirective vertical(Directive other) =>
      VerticalCompositeDirective.merge(this, other);

  VerticalCompositeDirective operator -(Directive that) => vertical(that);
}

class ErrorHandlerDirective extends Object with Directive {
  static final ErrorMatcher _defaultMatcher = (_) => true;

  final ErrorHandler _handler;
  final ErrorMatcher _matcher;
  final Directive _directive;

  ErrorHandlerDirective(this._directive, this._handler, {ErrorMatcher matcher})
      : _matcher = matcher == null ? _defaultMatcher : matcher;

  bool matches(Context ctx) => _directive.matches(ctx);

  Stream<Context> handle(Stream<Context> requests) =>
      _directive.handle(requests).handleError(_handler, test: _matcher);
}

class HandleDirective extends Object with Directive {
  final TransformFunction _transform;

  HandleDirective(this._transform);

  bool matches(Context ctx) => true;

  Stream<Context> handle(Stream<Context> requests) => _transform(requests);
}

HandleDirective transform(TransformFunction t) => new HandleDirective(t);

class NoOpDirective extends Object with Directive {
  bool matches(Context ctx) => true;

  Stream<Context> handle(Stream<Context> requests) => requests;
}

ConsumeDirective always(ConsumeFunction consumer) =>
    new ConsumeDirective(consumer);

class ConsumeDirective extends Object with Directive {
  final ConsumeFunction _consumer;

  ConsumeDirective(this._consumer);

  bool matches(Context ctx) => true;

  Stream<Context> handle(Stream<Context> requests) {
    requests.listen(_consumer);
    return new Stream.empty();
  }
}

class LogDirective extends Object with Directive {
  bool matches(Context ctx) => true;

  Stream<Context> handle(Stream<Context> requests) async* {
    await for (final Context ctx in requests) {
      final req = ctx.request;
      print("${new DateTime.now()}: ${req.method} ${req.path}");
      yield ctx;
    }
  }
}

final LogDirective logRoute = new LogDirective();

class TransformDirective extends Object with Directive {
  final TransformFunction _transform;

  TransformDirective(this._transform);

  bool matches(Context ctx) => true;

  Stream<Context> handle(Stream<Context> requests) => _transform(requests);
}

class MethodDirective extends Object with Directive {
  final String name;

  MethodDirective(String name) : name = name.toUpperCase();

  bool matches(Context ctx) => name == ctx.request.method.toUpperCase();

  Stream<Context> handle(Stream<Context> requests) => requests.where(matches);
}

final MethodDirective get = new MethodDirective("get");
final MethodDirective put = new MethodDirective("put");
final MethodDirective post = new MethodDirective("post");
final MethodDirective patch = new MethodDirective("patch");
final MethodDirective delete = new MethodDirective("delete");
final MethodDirective update = new MethodDirective("update");

abstract class ParserDirective implements Directive {
  factory ParserDirective.text() => new TextParserDirective();
  factory ParserDirective.json() => new JsonParserDirective();
  factory ParserDirective.urlEncoded() => new UrlEncodedParserDirective();
}

abstract class ContextProcessingException implements Exception {
  Context get context;
}

class BaseContextProcessingException implements ContextProcessingException {
  final Context context;

  BaseContextProcessingException(this.context);
}

class ParseException extends BaseContextProcessingException {
  final cause;

  ParseException(this.cause, Context context) : super(context);

  String toString() => "Parsing encountered an exception: $cause";
}

class TextParserDirective extends Object
    with Directive
    implements ParserDirective {
  bool matches(Context ctx) => ctx.request.headers.contentLength != null;

  Stream<Context> handle(Stream<Context> requests) {
    final controller = new StreamController<Context>();
    requests.listen((Context ctx) async {
      try {
        final byteLines = await ctx.request.input.toList();
        ctx.request.input.toList();
        ctx.request.body = byteLines.fold(
            "", (result, line) => result + new String.fromCharCodes(line));
        controller.add(ctx);
      } catch (e) {
        final ex = new ParseException(e, ctx);
        controller.addError(ex);
      }
    });
    return controller.stream;
  }
}

class JsonParserDirective extends Object
    with Directive
    implements ParserDirective {
  final _parser = new TextParserDirective();

  bool matches(Context ctx) => _parser.matches(ctx) &&
      ctx.request.headers.contentType != null &&
      ctx.request.headers.contentType.primaryType == "application" &&
      ctx.request.headers.contentType.subType == "json";

  Stream<Context> handle(Stream<Context> requests) {
    final controller = new StreamController<Context>();
    _parser.handle(requests).listen((Context ctx) async {
      try {
        ctx.request.body = JSON.decode(ctx.request.body);
      } catch (e) {
        final ex = new ParseException(e, ctx);
        controller.addError(ex);
      }
    });
    return controller.stream;
  }
}

class UrlEncodedParserDirective extends Object
    with Directive
    implements ParserDirective {
  final _parser = new TextParserDirective();

  bool matches(Context ctx) => _parser.matches(ctx) &&
      ctx.request.headers.contentType != null &&
      ctx.request.headers.contentType.primaryType == "application" &&
      ctx.request.headers.contentType.subType == "x-www-form-urlencoded";

  Stream<Context> handle(Stream<Context> requests) {
    final controller = new StreamController<Context>();
    _parser.handle(requests).listen((Context ctx) async {
      try {
        ctx.request.body = Uri.splitQueryString(ctx.request.body);
      } catch (e) {
        final ex = new ParseException(e, ctx);
        controller.addError(ex);
      }
    });
    return controller.stream;
  }
}

class PathDirective extends Object with Directive {
  final UrlMatcher _matcher;

  PathDirective(String path) : _matcher = new UrlMatcher.parse(path);

  PathDirective.matcher(this._matcher);

  bool matches(Context ctx) {
    final result = _matcher.matches(ctx.request.path);
    print(result);
    return result;
  }

  Stream<Context> handle(Stream<Context> requests) async* {
    await for (final Context ctx in requests) {
      ctx.request.parameters = _matcher.parameters(ctx.request.path);
      yield ctx;
    }
  }
}

PathDirective path(String path) => new PathDirective(path);

class VerticalCompositeDirective extends Object with Directive {
  final List<Directive> _directives;

  VerticalCompositeDirective(List<Directive> directives)
      : _directives = directives.isEmpty
            ? throw new ArgumentError.value(directives)
            : directives;

  bool matches(Context ctx) => _directives.first.matches(ctx);

  Stream<Context> handle(Stream<Context> requests) {
    return _directives.fold(
        requests,
        (Stream<Context> stream, Directive directive) =>
            directive.handle(stream.where(directive.matches)));
  }

  static VerticalCompositeDirective merge(Directive d1, Directive d2) {
    final l1 = d1 is VerticalCompositeDirective ? d1._directives : d1;
    final l2 = d2 is VerticalCompositeDirective ? d2._directives : d2;
    return new VerticalCompositeDirective(_concatenateLists(l1, l2));
  }
}

class HorizontalCompositeDirective extends Object with Directive {
  final List<Directive> _directives;

  HorizontalCompositeDirective(this._directives);

  bool matches(Context ctx) =>
      _directives.any((directive) => directive.matches(ctx));

  Stream<Context> handle(Stream<Context> requests) {
    final merged = new StreamController<Context>();
    final List _tuples = _directives.map((dir) {
      final controller = new StreamController<Context>();
      dir.handle(controller.stream).listen((ctx) => merged.add(ctx));
      return [controller, dir];
    }).toList();

    requests.listen((ctx) {
      final tuple = _tuples.firstWhere((t) => t[1].matches(ctx), orElse: null);
      if (null != tuple) tuple[0].add(ctx);
    }, onDone: () => _tuples.forEach((t) => t[0].close()));

    return merged.stream;
  }

  static HorizontalCompositeDirective merge(Directive d1, Directive d2) {
    final l1 = d1 is HorizontalCompositeDirective ? d1._directives : d1;
    final l2 = d2 is HorizontalCompositeDirective ? d2._directives : d2;
    return new HorizontalCompositeDirective(_concatenateLists(l1, l2));
  }
}

List _concatenateLists(a, b) {
  if (a is! List) a = [a];
  if (b is! List) b = [b];
  return []..addAll(a)..addAll(b);
}
