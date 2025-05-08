// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';

final class ReadinessCheck extends RequestHandler {
  const ReadinessCheck({required super.config});

  @override
  Future<Body> get(Request request) async {
    return Body.empty;
  }
}
