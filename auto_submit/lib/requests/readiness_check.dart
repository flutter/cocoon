// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart';

import '../server/request_handler.dart';

/// Handler for readiness checks.
class ReadinessCheck extends RequestHandler {
  const ReadinessCheck({required super.config});

  @override
  Future<Response> get() async {
    return Response.ok('OK');
  }

  @override
  Future<Response> run(Request request) async {
    return super.run(request);
  }
}
