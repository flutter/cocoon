// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group(CreateBranch, () {
    test('runs successfully', () async {
      final FakeHttpRequest request = FakeHttpRequest();
      final ApiRequestHandlerTester tester = ApiRequestHandlerTester(request: request);
      final RequestHandler handler = DartInternalTaskResult(
        config: FakeConfig(),
        authenticationProvider: FakeAuthenticationProvider(),
        requestBodyValue: utf8.encode('Test Body') as Uint8List,
      );
      final Body response = await tester.post(handler);
      expect(response, equals(Body.empty));
    });
  });
}
