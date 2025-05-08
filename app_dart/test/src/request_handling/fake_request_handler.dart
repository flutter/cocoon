// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/response.dart';

// ignore: must_be_immutable
final class FakeRequestHandler extends RequestHandler {
  FakeRequestHandler({
    required this.body,
    required super.config,
    this.statusCode,
    this.contentType,
  });

  final Response body;

  int callCount = 0;
  int? statusCode;
  ContentType? contentType;

  @override
  Future<Response> get(_) async {
    callCount++;
    _updateResponseMetadata();
    return body;
  }

  @override
  Future<Response> post(_) async {
    callCount++;
    _updateResponseMetadata();
    return body;
  }

  void _updateResponseMetadata() {
    if (statusCode case final statusCode?) {
      response!.statusCode = statusCode;
    }
    if (contentType case final contentType?) {
      response!.headers.contentType = contentType;
    }
  }
}
