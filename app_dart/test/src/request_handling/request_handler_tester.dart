// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/request_handling/request_handler.dart';

import 'body_decoder_extension.dart';
import 'fake_http.dart';

class RequestHandlerTester {
  RequestHandlerTester({FakeHttpRequest? request})
    : request = request ?? FakeHttpRequest();

  FakeHttpRequest request;

  /// This tester's [FakeHttpResponse], derived from [request].
  FakeHttpResponse get response => request.response;

  /// Executes [RequestHandler.get] on the specified [handler].
  Future<Response> get(RequestHandler handler) {
    // ignore: invalid_use_of_protected_member
    return handler.get(Request.fromHttpRequest(request));
  }

  Future<R> getJson<R extends Object?>(RequestHandler handler) async {
    // ignore: invalid_use_of_protected_member
    final response = await handler.get(Request.fromHttpRequest(request));
    return response.body.readAsJson();
  }

  /// Executes [RequestHandler.post] on the specified [handler].
  Future<Response> post(RequestHandler handler) {
    // ignore: invalid_use_of_protected_member
    return handler.post(Request.fromHttpRequest(request));
  }
}
