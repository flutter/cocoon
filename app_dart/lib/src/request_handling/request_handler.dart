// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import 'exceptions.dart';

/// Handles HTTP requests and responses.
@immutable
abstract base class RequestHandler {
  /// Creates a new [RequestHandler].
  const RequestHandler({required this.config});

  /// Global configuration of the server.
  @protected
  final Config config;

  /// Services an HTTP request.
  ///
  /// Subclasses should generally not override this method. Instead, they
  /// should override one of [get] or [post], depending on which methods
  /// they support.
  Future<void> service(
    Request request, {
    Future<void> Function(HttpStatusException)? onError,
  }) async {
    final response = request.response;
    try {
      try {
        Response body;
        switch (request.method) {
          case 'GET':
            body = await get(request);
            break;
          case 'POST':
            body = await post(request);
            break;
          default:
            throw MethodNotAllowed(request.method);
        }
        await _respond(response, body);
        return;
      } on HttpStatusException {
        rethrow;
      } catch (e, s) {
        log.error('Internal server error', e, s);
        throw InternalServerError('$e\n$s');
      }
    } on HttpStatusException catch (error) {
      if (onError != null) {
        await onError(error);
      }
      await _respond(
        response,
        Response.json({'error': error.message}, statusCode: error.statusCode),
      );
    }
  }

  /// Responds (using [response]).
  ///
  /// Returns a future that completes when [response] has been closed.
  Future<void> _respond(RequestResponse response, Response body) async {
    response.contentType = body.contentType;
    response.statusCode = body.statusCode;
    await response.addStream(body.body);
    await response.flush();
    await response.close();
  }

  /// Gets the value associated with the specified [key] in the request
  /// context.
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  U? getValue<U>(RequestKey<U> key, {bool allowNull = false}) {
    final value = Zone.current[key] as U?;
    if (!allowNull && value == null) {
      throw StateError(
        'Attempt to access ${key.name} while not in a request context',
      );
    }
    return value;
  }

  /// Services an HTTP GET.
  ///
  /// Subclasses should override this method if they support GET requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Response> get(Request request) async {
    throw const MethodNotAllowed('GET');
  }

  /// Services an HTTP POST.
  ///
  /// Subclasses should override this method if they support POST requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Response> post(Request request) async {
    throw const MethodNotAllowed('POST');
  }
}

/// A request received on a [RequestHandler].
abstract class Request {
  /// URL the request was served to, including query parameters.
  Uri get uri;

  /// The HTTP method of the request.
  String get method;

  /// The response that will be sent to the client.
  RequestResponse get response;

  /// Returns the value for the header with the given [name].
  ///
  /// The value must not have more than one value.
  ///
  /// If the header is not set, returns `null`.
  String? header(String name);

  /// Reads the body as bytes.
  ///
  /// Can be invoked multiple times.
  Future<Uint8List> readBodyAsBytes();

  /// Reads the body as a UTF-8 string.
  Future<String> readBodyAsString();

  /// Reads the body as a JSON object.
  Future<Map<String, Object?>> readBodyAsJson();
}

abstract interface class RequestResponse {
  int get statusCode;
  set statusCode(int value);

  set contentType(MediaType? value);

  Future<void> addStream(Stream<Uint8List> stream);
  Future<void> flush();
  Future<void> close();
  Future<dynamic> redirect(
    Uri location, {
    int status = HttpStatus.movedTemporarily,
  });
}

/// A key that can be used to index a value within the request context.
///
/// Subclasses will only need to deal directly with this class if they add
/// their own request context values.
@protected
class RequestKey<T> {
  const RequestKey(this.name);

  final String name;

  @override
  String toString() => '$runtimeType($name)';
}
