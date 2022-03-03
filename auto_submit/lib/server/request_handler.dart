// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../service/config.dart';
import 'exceptions.dart';

/// A class that services requests and returns responses.
@immutable
abstract class RequestHandler {
  const RequestHandler({
    required this.config,
  });
  final Config config;

  /// Services an HTTP request.
  ///
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Response> run(Request request) async {
    throw const MethodNotAllowed('GET');
  }
}
