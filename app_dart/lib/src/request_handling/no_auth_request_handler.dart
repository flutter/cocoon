// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'body.dart';
import 'exceptions.dart';
import 'request_handler.dart';

/// A [RequestHandler] that handles requests with no authentication.
///
/// No Auth requests enables [requestData]
///
/// `T` is the type of object that is returned as the body of the HTTP response
/// (before serialization). Subclasses whose HTTP responses don't include a
/// body should extend `RequestHandler<Body>` and return null in their service
/// handlers ([get] and [post]).
@immutable
abstract class NoAuthRequestHandler<T extends Body> extends RequestHandler<T> {
  /// Creates a new [NoAuthRequestHandler].
  const NoAuthRequestHandler({required super.config});

  /// Throws a [BadRequestException] if any of [requiredParameters] is missing
  /// from [requestData].
  @protected
  void checkRequiredParameters(List<String> requiredParameters) {
    final Iterable<String> missingParams =
        requiredParameters..removeWhere(requestData!.containsKey);
    if (missingParams.isNotEmpty) {
      throw BadRequestException(
        'Missing required parameter: ${missingParams.join(', ')}',
      );
    }
  }

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
  Uint8List? get requestBody => getValue<Uint8List>(NoAuthKey.requestBody);

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
  Map<String, dynamic>? get requestData =>
      getValue<Map<String, dynamic>>(NoAuthKey.requestData);

  @override
  Future<void> service(
    HttpRequest request, {
    Future<void> Function(HttpStatusException)? onError,
  }) async {
    List<int> body;
    try {
      body = await request.expand<int>((List<int> chunk) => chunk).toList();
    } catch (error) {
      final response = request.response;
      response
        ..statusCode = HttpStatus.internalServerError
        ..write('$error');
      await response.flush();
      await response.close();
      return;
    }

    Map<String, dynamic>? requestData = const <String, dynamic>{};
    if (body.isNotEmpty) {
      try {
        requestData = json.decode(utf8.decode(body)) as Map<String, dynamic>?;
      } on FormatException {
        // The HTTP request body is not valid UTF-8 encoded JSON. This is
        // allowed; just let [requestData] be null.
      } catch (error) {
        final response = request.response;
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('$error');
        await response.flush();
        await response.close();
        return;
      }
    }

    await runZoned<Future<void>>(
      () async {
        await super.service(request);
      },
      zoneValues: <NoAuthKey<dynamic>, Object?>{
        NoAuthKey.requestBody: Uint8List.fromList(body),
        NoAuthKey.requestData: requestData,
      },
    );
  }
}

@visibleForTesting
class NoAuthKey<T> extends RequestKey<T> {
  const NoAuthKey._(super.name);

  static const NoAuthKey<Uint8List> requestBody = NoAuthKey<Uint8List>._(
    'requestBody',
  );
  static const NoAuthKey<Map<String, dynamic>> requestData =
      NoAuthKey<Map<String, dynamic>>._('requestData');
}
