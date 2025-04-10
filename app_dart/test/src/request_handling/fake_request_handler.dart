// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';

// ignore: must_be_immutable
class FakeRequestHandler extends RequestHandler<Body> {
  FakeRequestHandler({
    required this.body,
    required super.config,
    this.statusCode,
    this.reasonPhrase,
  });

  final Body body;

  int callCount = 0;
  int? statusCode;
  String? reasonPhrase;

  @override
  Future<Body> get() async {
    callCount++;
    _updateResponseMetadata();
    return body;
  }

  @override
  Future<Body> post() async {
    callCount++;
    _updateResponseMetadata();
    return body;
  }

  void _updateResponseMetadata() {
    if (statusCode case final statusCode?) {
      response!.statusCode = statusCode;
    }
    if (reasonPhrase case final reasonPhrase?) {
      response!.reasonPhrase = reasonPhrase;
    }
  }
}
