// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../model/google/token_info.dart';
import '../request_handling/authentication.dart';
import '../requests/exceptions.dart';
import 'request_handler.dart';
import '../service/config.dart';

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
abstract class ApiRequestHandler extends RequestHandler {
  /// Creates a new [ApiRequestHandler].
  const ApiRequestHandler({
    required Config config,
    required this.authenticationProvider,
    this.requestBodyValue,
  }) : super(config: config);

  /// Service responsible for authenticating this [Request].
  final AuthenticationProvider authenticationProvider;

  /// Throws a [BadRequestException] if any of [requiredParameters] is missing
  /// from [requestData].
  @protected
  void checkRequiredParameters(List<String> requiredParameters) {
    final Iterable<String> missingParams = requiredParameters..removeWhere(requestData!.containsKey);
    if (missingParams.isNotEmpty) {
      throw BadRequestException('Missing required parameter: ${missingParams.join(', ')}');
    }
  }

  /// Gets [TokenInfo] using X-Flutter-IdToken header from an authenticated request.
  @protected
  Future<TokenInfo> tokenInfo(Request request) async {
    return authenticationProvider.tokenInfo(request);
  }

  /// Throws a [BadRequestException] if any of [requiredQueryParameters] are missing from [requestData].
  @protected
  void checkRequiredQueryParameters(List<String> requiredQueryParameters) {
    final Iterable<String> missingParams = requiredQueryParameters
      ..removeWhere(request!.url.queryParameters.containsKey);
    if (missingParams.isNotEmpty) {
      throw BadRequestException('Missing required parameter: ${missingParams.join(', ')}');
    }
  }

  /// The authentication context associated with the HTTP request.
  ///
  /// This is guaranteed to be non-null. If the request was unauthenticated,
  /// the request will be denied.
  @protected
  AuthenticatedContext? get authContext => getValue<AuthenticatedContext>(ApiKey.authContext);

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
  Uint8List? get requestBody => requestBodyValue ?? getValue<Uint8List>(ApiKey.requestBody);

  /// Used for injecting [requestBody] in tests.
  final Uint8List? requestBodyValue;

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
  Map<String, dynamic>? get requestData => getValue<Map<String, dynamic>>(ApiKey.requestData);
}

class ApiKey<T> extends RequestKey<T> {
  const ApiKey._(String name) : super(name);

  static const ApiKey<Uint8List> requestBody = ApiKey<Uint8List>._('requestBody');
  static const ApiKey<AuthenticatedContext> authContext = ApiKey<AuthenticatedContext>._('authenticatedContext');
  static const ApiKey<Map<String, dynamic>> requestData = ApiKey<Map<String, dynamic>>._('requestData');
}
