// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import 'exceptions.dart';

/// A class that services HTTP requests and returns HTTP responses.
@immutable
abstract base class RequestHandler {
  /// Creates a new [RequestHandler].
  const RequestHandler({required this.config});

  /// The global configuration of this AppEngine server.
  final Config config;

  /// Services an HTTP request.
  ///
  /// Subclasses should generally not override this method. Instead, they
  /// should override one of [get] or [post], depending on which methods
  /// they support.
  Future<void> service(
    HttpRequest request, {
    Future<void> Function(HttpStatusException)? onError,
  }) {
    return runZoned<Future<void>>(
      () async {
        final response = request.response;
        try {
          try {
            Body body;
            switch (request.method) {
              case 'GET':
                body = await get(Request.fromHttpRequest(request));
                break;
              case 'POST':
                body = await post(Request.fromHttpRequest(request));
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
          response
            ..statusCode = error.statusCode
            ..write(error.message);
          await response.flush();
          await response.close();
          return;
        }
      },
      zoneValues: <RequestKey<dynamic>, Object>{
        RequestKey.response: request.response,
      },
    );
  }

  /// Responds (using [response]).
  ///
  /// Returns a future that completes when [response] has been closed.
  Future<void> _respond(HttpResponse response, Body body) async {
    response.headers.contentType = body.contentType;
    await response.addStream(body.serialize());
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
  U? getValue<U>(RequestKey<U> key, {bool allowNull = false}) {
    final value = Zone.current[key] as U?;
    if (!allowNull && value == null) {
      throw StateError(
        'Attempt to access ${key.name} while not in a request context',
      );
    }
    return value;
  }

  /// Gets the current [HttpResponse].
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  HttpResponse? get response => getValue<HttpResponse>(RequestKey.response);

  /// Services an HTTP GET.
  ///
  /// Subclasses should override this method if they support GET requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Body> get(Request request) async {
    throw const MethodNotAllowed('GET');
  }

  /// Services an HTTP POST.
  ///
  /// Subclasses should override this method if they support POST requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Body> post(Request request) async {
    throw const MethodNotAllowed('POST');
  }
}

/// A request received on a [RequestHandler].
abstract mixin class Request {
  /// Creates a [Request] by wrapping an existing [HttpRequest].
  factory Request.fromHttpRequest(HttpRequest request) = _HttpRequest;

  /// URL the request was served to, including query parameters.
  Uri get uri;

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
  Future<String> readBodyAsString() async {
    return utf8.decode(await readBodyAsBytes());
  }

  /// A special decoder that decodes UTF-8 bytes into JSON values.
  ///
  /// Backend implementations in the Dart SDK typically optimize this fused
  /// decoder compared to the default [dart.JsonDecoder] which operates on
  /// UTF-16 strings.
  ///
  /// See <https://github.com/dart-lang/sdk/issues/55996> for more information.
  static final _utf8JsonDecoder = utf8.decoder.fuse(json.decoder);

  /// Reads the body as a JSON object.
  Future<Map<String, Object?>> readBodyAsJson() async {
    final bytes = await readBodyAsBytes();
    if (bytes.isEmpty) {
      return {};
    }
    final result = _utf8JsonDecoder.convert(await readBodyAsBytes());
    return result as Map<String, Object?>;
  }
}

/// A request that is backed by an [HttpRequest].
final class _HttpRequest with Request {
  _HttpRequest(this._request);
  final HttpRequest _request;

  @override
  Uri get uri => _request.uri;

  @override
  String? header(String name) {
    return _request.headers.value(name);
  }

  @override
  Future<Uint8List> readBodyAsBytes() async {
    if (_bodyAsBytes case final previousCall?) {
      return previousCall;
    }
    final builder = await _request.fold(BytesBuilder(copy: false), (
      builder,
      data,
    ) {
      builder.add(data);
      return builder;
    });
    return _bodyAsBytes = builder.takeBytes();
  }

  Uint8List? _bodyAsBytes;
}

/// A key that can be used to index a value within the request context.
///
/// Subclasses will only need to deal directly with this class if they add
/// their own request context values.
@protected
class RequestKey<T> {
  const RequestKey(this.name);

  final String name;

  static const RequestKey<HttpRequest> request = RequestKey<HttpRequest>(
    'request',
  );
  static const RequestKey<HttpResponse> response = RequestKey<HttpResponse>(
    'response',
  );

  @override
  String toString() => '$runtimeType($name)';
}
