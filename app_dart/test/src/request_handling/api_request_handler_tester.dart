// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/response.dart';
import 'package:meta/meta.dart';

import 'request_handler_tester.dart';

class ApiRequestHandlerTester extends RequestHandlerTester {
  ApiRequestHandlerTester({
    super.request, //
    FakeAuthenticatedContext? context,
  }) : context = context ?? FakeAuthenticatedContext();

  FakeAuthenticatedContext context;
  set requestData(Map<String, Object?> requestData) {
    request.body = jsonEncode(requestData);
  }

  @override
  @protected
  Future<Response> run(Future<Response> Function() callback) {
    return super.run(() {
      return runZoned(
        () {
          return callback();
        },
        zoneValues: <RequestKey<dynamic>, Object>{ApiKey.authContext: context},
      );
    });
  }
}
