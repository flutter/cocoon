// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';

@immutable
class ReadinessCheck extends RequestHandler<Body> {
  @override
  Future<Body> get() async {
    return Body.empty;
  }
}
