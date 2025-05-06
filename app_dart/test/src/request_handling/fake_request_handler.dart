// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/request_handling/request_handler.dart';

// ignore: must_be_immutable
class FakeRequestHandler extends RequestHandler {
  FakeRequestHandler({
    required this.body,
    required super.config,
    this.statusCode,
  });

  final Body body;
  int callCount = 0;
  int? statusCode;

  @override
  Future<Response> get(_) async {
    callCount++;
    return Response(body, statusCode: statusCode ?? HttpStatus.ok);
  }

  @override
  Future<Response> post(_) async {
    callCount++;
    return Response(body, statusCode: statusCode ?? HttpStatus.ok);
  }
}
