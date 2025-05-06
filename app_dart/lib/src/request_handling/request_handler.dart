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
///
/// `T` is the type of object that is returned as the body of the HTTP response
/// (before serialization). Subclasses whose HTTP responses don't include a
/// body should extend `RequestHandler` and return null in their service
/// handlers ([get] and [post]).

abstract class RequestHandler {
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
  }) async {
    Response response;
    try {
      response = await switch (request.method) {
        'GET' => get(Request.fromHttpRequest(request)),
        'POST' => post(Request.fromHttpRequest(request)),
        _ => throw MethodNotAllowed(request.method),
      };
    } on HttpStatusException catch (e) {
      response = Response(
        Body.json({'error': e.message}),
        statusCode: e.statusCode,
      );
    } catch (e, s) {
      log.error('Unhandled internal server error', e, s);
      response = Response.internalServerError(Body.json({'error': '$e'}));
    }
    await _respond(request.response, response);
  }

  /// Responds (using [response]) with an optional [body].
  ///
  /// Returns a future that completes when [response] has been closed.
  Future<void> _respond(HttpResponse http, Response response) async {
    http.statusCode = response.statusCode;
    if (response.body.contentType case final contentType?) {
      http.headers.contentType = contentType;
    }
    await http.addStream(response.body.contents);
    await http.flush();
    await http.close();
  }

  @Deprecated('Do not add more usages of getValue, use parameters instead')
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
  ///
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Response> get(Request request) async {
    throw const MethodNotAllowed('GET');
  }

  /// Services an HTTP POST.
  ///
  /// Subclasses should override this method if they support POST requests.
  ///
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Response> post(Request request) async {
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

/// A response computed by a [RequestHandler].
@immutable
final class Response {
  /// Create a response with the provided body and HTTP status code.
  ///
  /// Prefer one of the named constructors where able.
  const Response(this.body, {required this.statusCode});

  /// Create a response indicating `200 OK`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/200>
  const Response.ok([Body body = const Body.empty()]) //
    : this(body, statusCode: HttpStatus.ok);

  /// Create a response indcating `400 Bad Request`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/400>.
  const Response.badRequest([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.badRequest);

  /// Create a response indcating `401 Unauthorized`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/401>.
  const Response.unauthorized([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.unauthorized);

  /// Create a response indcating `403 Forbidden`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/403>.
  const Response.forbidden([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.forbidden);

  /// Create a response indcating `404 Not Found`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/404>.
  const Response.notFound([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.notFound);

  /// Create a response indcating `405 Method Not Allowed`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/405>.
  const Response.methodNotAllowed([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.methodNotAllowed);

  /// Create a response indcating `409 Conflict`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/409>.
  const Response.conflict([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.conflict);

  /// Create a response indcating `500 Internal Server Error`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/500>.
  const Response.internalServerError([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.internalServerError);

  /// Create a response indcating `503 Service Unavailable`.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/500>.
  const Response.serviceUnavailable([Body body = const Body.empty()])
    : this(body, statusCode: HttpStatus.serviceUnavailable);

  /// The [HttpStatus] of the response.
  final int statusCode;

  /// The body of the response.
  final Body body;
}

abstract final class Body {
  const Body({this.contentType});

  const factory Body.empty() = _EmptyBody;

  const factory Body.json(Object? encodable) = _JsonBody;

  const factory Body.stream(
    Stream<List<int>> stream, { //
    ContentType? contentType,
  }) = _StreamBody;

  const factory Body.string(
    String body, { //
    ContentType? contentType,
  }) = _TextBody;

  const factory Body.bytes(
    Uint8List bytes, { //
    ContentType? contentType,
  }) = _BytesBody;

  /// The content type describing the body.
  final ContentType? contentType;

  /// Returns the contents of the body, if any.
  Stream<List<int>> get contents;
}

final class _EmptyBody implements Body {
  const _EmptyBody();

  @override
  ContentType? get contentType => ContentType.text;

  @override
  Stream<Uint8List> get contents => const Stream.empty();
}

final class _JsonBody implements Body {
  const _JsonBody(this._encodable);

  @override
  ContentType? get contentType => ContentType.json;

  @override
  Stream<List<int>> get contents {
    return Stream.fromIterable([_utf8JsonEncoder.convert(_encodable)]);
  }

  final Object? _encodable;
  static final _utf8JsonEncoder = JsonUtf8Encoder();
}

final class _StreamBody implements Body {
  const _StreamBody(this.contents, {this.contentType});

  @override
  final Stream<List<int>> contents;

  @override
  final ContentType? contentType;
}

final class _BytesBody implements Body {
  const _BytesBody(this._contents, {this.contentType});

  @override
  Stream<List<int>> get contents {
    return Stream.fromIterable([_contents]);
  }

  final Uint8List _contents;

  @override
  final ContentType? contentType;
}

final class _TextBody implements Body {
  const _TextBody(this._contents, {this.contentType});

  @override
  Stream<List<int>> get contents {
    return Stream.fromIterable([utf8.encode(_contents)]);
  }

  final String _contents;

  @override
  final ContentType? contentType;
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
