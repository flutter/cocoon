// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';

import 'exceptions.dart';

/// A class based on [RequestHandler] for serving static files.
@immutable
class StaticFileHandler {
  /// Creates a new [StaticFileHandler].
  const StaticFileHandler();

  /// The location for the Flutter application
  // TODO(chillers): Remove this when deployed for production use. https://github.com/flutter/cocoon/issues/472
  static const String flutterBetaUrlPrefix = '/v2';

  /// Services an HTTP request.
  Future<void> service(HttpRequest request) {
    final HttpResponse response = request.response;
    return runZoned<Future<void>>(() async {
      try {
        try {
          switch (request.method) {
            case 'GET':
              await get(request);
              break;
            default:
              throw MethodNotAllowed(request.method);
          }
          await _respond(response: response);
          return;
        } on HttpStatusException {
          rethrow;
        } catch (error, stackTrace) {
          log.error('$error\n$stackTrace');
          throw InternalServerError('$error\n$stackTrace');
        }
      } on HttpStatusException catch (error) {
        await response.close();
        response
          ..statusCode = error.statusCode
          ..write(error.message);
        await response.flush();
        await response.close();
        return;
      }
    }, zoneValues: <RequestKey<dynamic>, Object>{
      RequestKey.request: request,
      RequestKey.response: response,
      RequestKey.log: loggingService,
    });
  }

  /// Responds (using [response]) with the specified [status] and optional
  /// [body].
  ///
  /// Returns a future that completes when [response] has been closed.
  Future<void> _respond(
      {int status = HttpStatus.ok, @required HttpResponse response}) async {
    assert(status != null);
    assert(response != null);

    response.statusCode = status;
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
  T getValue<T>(RequestKey<T> key, {bool allowNull = false}) {
    final T value = Zone.current[key];
    if (!allowNull && value == null) {
      throw StateError(
          'Attempt to access ${key.name} while not in a request context');
    }
    return value;
  }

  /// Gets the current [Logging] instance.
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  Logging get log => getValue<Logging>(RequestKey.log);

  /// Services an HTTP GET Request for static files.
  Future<HttpResponse> get(HttpRequest request) async {
    final HttpResponse response = request.response;

    String filePath = request.uri.toFilePath();
    // TODO(chillers): Remove this when deployed for production use. https://github.com/flutter/cocoon/issues/472
    filePath = filePath.replaceFirst(flutterBetaUrlPrefix, '');

    final String resultPath = filePath == '/' ? '/index.html' : filePath;
    const String basePath = 'build/web';
    final File file = File('$basePath$resultPath');

    if (file.existsSync()) {
      try {
        final String mimeType = lookupMimeType(resultPath);
        response.headers.contentType = ContentType.parse(mimeType);
        await response.addStream(file.openRead());
        return response;
      } catch (error, stackTrace) {
        throw InternalServerError('$error\n$stackTrace');
      }
    } else {
      throw NotFoundException(resultPath);
    }
  }
}

/// A key that can be used to index a value within the request context.
///
/// Subclasses will only need to deal directly with this class if they add
/// their own request context values.
@visibleForTesting
class RequestKey<T> {
  const RequestKey(this.name);

  final String name;

  static const RequestKey<HttpRequest> request =
      RequestKey<HttpRequest>('request');
  static const RequestKey<HttpResponse> response =
      RequestKey<HttpResponse>('response');
  static const RequestKey<Logging> log = RequestKey<Logging>('log');

  @override
  String toString() => '$runtimeType($name)';
}
