// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../common/handler.dart';

/// Handler for readiness checks.
class ReadinessCheck extends Handler {
  const ReadinessCheck() : super('readiness_check');
  @override
  Future<Response> get(Context context, Request request) async {
    return Response.ok('OK');
  }
}
