// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
///  * If a request body is specified, it must be encoded as a JSON map.
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

  /// The JSON data specified in the HTTP request body.
  ///
  /// This is guaranteed to be non-null. If the request body was empty, this
  /// will be an empty map.
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

    Map<String, dynamic> requestData;
    try {
      final String body = await utf8.decoder.bind(request).join();
      requestData = body.isEmpty ? const <String, dynamic>{} : json.decode(body);
    } catch (error) {
      final HttpResponse response = request.response;
      response
        ..statusCode = HttpStatus.badRequest
        ..write('$error');
      await response.flush();
      await response.close();
      return;
    }

    await runZoned<Future<void>>(() async {
      await super.service(request);
    }, zoneValues: <ApiKey<dynamic>, Object>{
      ApiKey.authContext: context,
      ApiKey.requestData: requestData,
    });
  }
}

@visibleForTesting
class ApiKey<T> extends RequestKey<T> {
  const ApiKey._(String name) : super(name);

  static const ApiKey<AuthenticatedContext> authContext =
      ApiKey<AuthenticatedContext>._('authenticatedContext');
  static const ApiKey<Map<String, dynamic>> requestData =
      ApiKey<Map<String, dynamic>>._('requestData');
}
