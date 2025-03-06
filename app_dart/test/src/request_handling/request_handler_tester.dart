// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:http/testing.dart' as http;
import 'package:meta/meta.dart';

import 'fake_http.dart';

class RequestHandlerTester {
  RequestHandlerTester({FakeHttpRequest? request, this.httpClient}) {
    this.request = request ?? FakeHttpRequest();
  }

  FakeHttpRequest? request;
  http.MockClient? httpClient;

  /// This tester's [FakeHttpResponse], derived from [request].
  FakeHttpResponse get response => request!.response;

  /// Executes [RequestHandler.get] on the specified [handler].
  Future<T> get<T extends Body>(RequestHandler<T> handler) {
    return run<T>(() {
      return handler.get(); // ignore: invalid_use_of_protected_member
    });
  }

  /// Executes [RequestHandler.post] on the specified [handler].
  Future<T> post<T extends Body>(RequestHandler<T> handler) {
    return run<T>(() {
      return handler.post(); // ignore: invalid_use_of_protected_member
    });
  }

  @protected
  Future<T> run<T extends Body>(Future<T> Function() callback) {
    return runZoned<Future<T>>(
      () {
        return callback();
      },
      zoneValues: <RequestKey<dynamic>, Object?>{
        RequestKey.request: request,
        RequestKey.response: response,
        RequestKey.httpClient: httpClient,
      },
    );
  }
}
