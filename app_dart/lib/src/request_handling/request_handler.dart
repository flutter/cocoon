// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';

import 'body.dart';
import 'exceptions.dart';

/// A class that services HTTP requests and returns HTTP responses.
///
/// `T` is the type of object that is returned as the body of the HTTP response
/// (before serialization). Subclasses whose HTTP responses don't include a
/// body should extend `RequestHandler<Body>` and return null in their service
/// handlers ([get] and [post]).
@immutable
abstract class RequestHandler<T extends Body> {
  /// Creates a new [RequestHandler].
  const RequestHandler({
    @required this.config,
  }) : assert(config != null);

  /// The global configuration of this AppEngine server.
  final Config config;

  /// Services an HTTP request.
  ///
  /// Subclasses should generally not override this method. Instead, they
  /// should override one of [get] or [post], depending on which methods
  /// they support.
  Future<void> service(HttpRequest request) {
    return runZoned<Future<void>>(() async {
      final HttpResponse response = request.response;
      try {
        try {
          T body;
          switch (request.method) {
            case 'GET':
              body = await get();
              break;
            case 'POST':
              body = await post();
              break;
            default:
              throw MethodNotAllowed(request.method);
          }
          respond(body: body == null ? null : json.encode(body.toJson()));
          return;
        } on HttpStatusException {
          rethrow;
        } catch (error, stackTrace) {
          print('$error\n$stackTrace');
          throw InternalServerError('$error\n$stackTrace');
        }
      } on HttpStatusException catch (error) {
        response
          ..statusCode = error.statusCode
          ..write(error.message);
        await response.flush();
        await response.close();
        return;
      }
    }, zoneValues: <RequestKey<dynamic>, Object>{
      RequestKey.request: request,
      RequestKey.response: request.response,
    });
  }

  /// Responds (using [response]) with the specified [status] and optional
  /// [body].
  ///
  /// Returns a future that completes when [response] has been closed.
  @protected
  Future<void> respond({int status = HttpStatus.ok, String body}) async {
    assert(status != null);
    response.statusCode = status;
    if (body != null) {
      response.write(body);
    }
    await response.flush();
    await response.close();
  }

  /// Gets the value associated with the specified [key] in the request
  /// context.
  ///
  /// Concrete subclasses should not call this directly. Instead, they should
  /// access the getters that are tied to specific keys, such as [request]
  /// and [response].
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  T getValue<T>(RequestKey<T> key) {
    final T value = Zone.current[key];
    if (value == null) {
      throw StateError('Attempt to access ${key.name} while not in a request context');
    }
    return value;
  }

  /// Gets the current [HttpRequest].
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  HttpRequest get request => getValue<HttpRequest>(RequestKey.request);

  /// Gets the current [HttpResponse].
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  HttpResponse get response => getValue<HttpResponse>(RequestKey.response);

  /// Services an HTTP GET.
  ///
  /// Subclasses should override this method if they support GET requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<T> get() {
    throw MethodNotAllowed('GET');
  }

  /// Services an HTTP POST.
  ///
  /// Subclasses should override this method if they support POST requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<T> post() {
    throw MethodNotAllowed('POST');
  }
}

/// A key that can be used to index a value within the request context.
///
/// Subclasses will only need to deal directly with this class if they add
/// their own request context values.
@protected
class RequestKey<T> {
  const RequestKey(this.name);

  final String name;

  static const RequestKey<HttpRequest> request = RequestKey<HttpRequest>('request');
  static const RequestKey<HttpResponse> response = RequestKey<HttpResponse>('response');

  @override
  String toString() => '$runtimeType($name)';
}
