library quick.test.mock;

import 'dart:io' show HttpHeaders, HttpRequest;

import 'package:quick/quick.dart';
import 'package:mock/mock.dart';


@proxy
class MockRequest extends Mock implements Request {
  noSuchMethod(inv) => super.noSuchMethod(inv);
}

@proxy
class MockHttpRequest extends Mock implements HttpRequest {
  noSuchMethod(inv) => super.noSuchMethod(inv);
}

@proxy
class MockHeaders extends Mock implements HttpHeaders {
  noSuchMethod(inv) => super.noSuchMethod(inv);
}