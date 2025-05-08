// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/response.dart';

// ignore: must_be_immutable
final class FakeRequestHandler extends RequestHandler {
  FakeRequestHandler({required this.body, required super.config});

  final Response body;
  int callCount = 0;

  @override
  Future<Response> get(_) async {
    callCount++;
    return body;
  }

  @override
  Future<Response> post(_) async {
    callCount++;
    return body;
  }
}
