// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';

import 'authentication.dart';
import 'body.dart';
import 'exceptions.dart';
import 'request_handler.dart';

/// A [RequestHandler] that handles API requests.
///
/// API requests adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
///
/// `T` is the type of object that is returned as the body of the HTTP response
/// (before serialization). Subclasses whose HTTP responses don't include a
/// body should extend `RequestHandler<Body>` and return null in their service
/// handlers ([get] and [post]).
@immutable
abstract class ApiRequestHandler<T extends Body> extends RequestHandler<T> {
  /// Creates a new [ApiRequestHandler].
  const ApiRequestHandler({
    @required Config config,
    @required this.authenticationProvider,
  })  : assert(authenticationProvider != null),
        super(config: config);

  /// The object responsible for authenticating requests, guaranteed to be
  /// non-null.
  final AuthenticationProvider authenticationProvider;

  /// Throws a [BadRequestException] if any of [requiredParameters] is missing
  /// from [requestData].
  @protected
  void checkRequiredParameters(List<String> requiredParameters) {
    final Iterable<String> missingParams = requiredParameters..removeWhere(requestData.containsKey);
    if (missingParams.isNotEmpty) {
      throw BadRequestException('Missing required parameter: ${missingParams.join(', ')}');
    }
  }

  /// The authentication context associated with the HTTP request.
  ///
  /// This is guaranteed to be non-null. If the request was unauthenticated,
  /// the request will be denied.
  @protected
  AuthenticatedContext get authContext => getValue<AuthenticatedContext>(ApiKey.authContext);

  /// The raw byte contents of the HTTP request body.
  ///
  /// If the request did not specify any content in the body, this will be an
  /// empty list. It will never be null.
  ///
  /// See also:
  ///
  ///  * [requestData], which contains the JSON-decoded [Map] of the request
  ///    body content (if applicable).
  @protected
  Uint8List get requestBody => getValue<Uint8List>(ApiKey.requestBody);

  /// The JSON data specified in the HTTP request body.
  ///
  /// This is guaranteed to be non-null. If the request body was empty, or if
  /// it contained non-JSON or binary (non-UTF-8) data, this will be an empty
  /// map.
  ///
  /// See also:
  ///
  ///  * [requestBody], which specifies the raw bytes of the HTTP request body.
  @protected
  Map<String, dynamic> get requestData => getValue<Map<String, dynamic>>(ApiKey.requestData);

  @override
  Future<void> service(HttpRequest request) async {
    AuthenticatedContext context;
    try {
      context = await authenticationProvider.authenticate(request);
    } on Unauthenticated catch (error) {
      final HttpResponse response = request.response;
      response
        ..statusCode = HttpStatus.unauthorized
        ..write(error.message);
      await response.flush();
      await response.close();
      return;
    }

    List<int> body;
    try {
      body = await request.expand<int>((Uint8List chunk) => chunk).toList();
    } catch (error) {
      final HttpResponse response = request.response;
      response
        ..statusCode = HttpStatus.internalServerError
        ..write('$error');
      await response.flush();
      await response.close();
      return;
    }

    Map<String, dynamic> requestData = const <String, dynamic>{};
    if (body.isNotEmpty) {
      try {
        requestData = json.decode(utf8.decode(body));
      } on FormatException {
        // The HTTP request body is not valid UTF-8 encoded JSON. This is
        // allowed; just let [requestData] be null.
      } catch (error) {
        final HttpResponse response = request.response;
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('$error');
        await response.flush();
        await response.close();
        return;
      }
    }

    await runZoned<Future<void>>(() async {
      await super.service(request);
    }, zoneValues: <ApiKey<dynamic>, Object>{
      ApiKey.authContext: context,
      ApiKey.requestBody: Uint8List.fromList(body),
      ApiKey.requestData: requestData,
    });
  }
}

@visibleForTesting
class ApiKey<T> extends RequestKey<T> {
  const ApiKey._(String name) : super(name);

  static const ApiKey<Uint8List> requestBody = ApiKey<Uint8List>._('requestBody');
  static const ApiKey<AuthenticatedContext> authContext =
      ApiKey<AuthenticatedContext>._('authenticatedContext');
  static const ApiKey<Map<String, dynamic>> requestData =
      ApiKey<Map<String, dynamic>>._('requestData');
}
