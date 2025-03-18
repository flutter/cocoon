// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';

// ignore: must_be_immutable
class FakeRequestHandler extends RequestHandler<Body> {
  FakeRequestHandler({required this.body, required super.config});

  final Body body;

  int callCount = 0;

  @override
  Future<Body> get() async {
    callCount++;
    return body;
  }

  @override
  Future<Body> post() async {
    return body;
  }
}
