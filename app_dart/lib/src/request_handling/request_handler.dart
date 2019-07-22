// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';

import 'exceptions.dart';

/// A class that services HTTP requests and returns HTTP responses.
@immutable
abstract class RequestHandler {
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
  Future<void> service(HttpRequest request) async {
    final HttpResponse response = request.response;
    try {
      try {
        switch (request.method) {
          case 'GET':
            await get(request, response);
            return;
          case 'POST':
            await post(request, response);
            return;
          default:
            throw MethodNotAllowed(request.method);
        }
      } on HttpException {
        rethrow;
      } catch (error, stackTrace) {
        print('$error\n$stackTrace');
        throw InternalServerError('$error\n$stackTrace');
      }
    } on HttpException catch (error) {
      response
        ..statusCode = error.statusCode
        ..write(error.message);
      await response.flush();
      await response.close();
      return;
    }
  }

  /// Services an HTTP GET.
  ///
  /// Subclasses should override this method if they support GET requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<void> get(HttpRequest request, HttpResponse response) {
    throw MethodNotAllowed('GET');
  }

  /// Services an HTTP POST.
  ///
  /// Subclasses should override this method if they support POST requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<void> post(HttpRequest request, HttpResponse response) {
    throw MethodNotAllowed('POST');
  }
}
