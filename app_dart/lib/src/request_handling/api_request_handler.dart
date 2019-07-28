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
  /// from  [request].
  @protected
  void checkRequiredParameters(Map<String, dynamic> request, List<String> requiredParameters) {
    final Iterable<String> missingParams = requiredParameters..removeWhere(request.containsKey);
    if (missingParams.isNotEmpty) {
      throw BadRequestException('Missing required parameter: ${missingParams.join(', ')}');
    }
  }

  @protected
  AuthenticatedContext get authContext => getValue<AuthenticatedContext>(ApiKey.authContext);

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

    final String body = await utf8.decoder.bind(request).join();
    final Map<String, dynamic> requestData = body == null ? null : json.decode(body);

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
