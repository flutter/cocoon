// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../requests/exceptions.dart';
import '../service/config.dart';

@immutable
abstract class RequestHandler {
  const RequestHandler({
    required this.config,
  });

  final Config config;

  /// Services a request.
  ///
  /// The default implementation will respond with 405 method not allowed.
  @protected
  Future<Response> run(Request request) async {
    try {
      switch (request.method) {
        case 'GET':
          return await get() as Response;
        case 'POST':
          return await post(request) as Response;
        default:
          throw MethodNotAllowed(request.method);
      }
    } on HttpStatusException {
      rethrow;
    }
  }

  /// Services a GET request.
  ///
  /// Subclasses should override this method if they support GET requests.
  /// The default implementation will respond with 405 method not allowed.
  @protected
  Future get() async {
    throw const MethodNotAllowed('GET');
  }

  /// Services a POST request.
  ///
  /// Subclasses should override this method if they support POST requests.
  /// The default implementation will respond with  405 method not allowed.
  @protected
  Future post(Request request) async {
    throw const MethodNotAllowed('POST');
  }
}
