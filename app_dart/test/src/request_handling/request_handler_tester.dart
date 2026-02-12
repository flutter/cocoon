// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/response.dart';
import 'package:meta/meta.dart';

class RequestHandlerTester {
  RequestHandlerTester({FakeHttpRequest? request})
    : request = request ?? FakeHttpRequest();

  FakeHttpRequest request;

  /// Executes [RequestHandler.get] on the specified [handler].
  Future<Response> get(RequestHandler handler) {
    return run(() {
      // ignore: invalid_use_of_protected_member
      return handler.get(request.toRequest());
    });
  }

  /// Executes [RequestHandler.post] on the specified [handler].
  Future<Response> post(RequestHandler handler) {
    return run(() {
      // ignore: invalid_use_of_protected_member
      return handler.post(request.toRequest());
    });
  }

  @protected
  Future<Response> run(Future<Response> Function() callback) {
    return callback();
  }
}
