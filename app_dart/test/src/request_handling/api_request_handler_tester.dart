// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'fake_dashboard_authentication.dart';
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
}
