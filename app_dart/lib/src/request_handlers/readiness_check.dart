// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';

final class ReadinessCheck extends RequestHandler {
  const ReadinessCheck({required super.config});

  @override
  Future<Response> get(Request request) async {
    return Response.emptyOk;
  }
}
