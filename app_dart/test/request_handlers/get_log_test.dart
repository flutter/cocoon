// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handlers/get_log.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('GetLog', () {
    FakeConfig config;
    FakeDatastoreDB db;
    GetLog handler;

    setUp(() {
      config = FakeConfig();
      db = FakeDatastoreDB();
      handler = GetLog(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: db),
      );
    });

    test('owner key param required', () async {
      final ApiRequestHandlerTester tester = ApiRequestHandlerTester();

      expect(tester.get(handler), throwsA(isA<BadRequestException>()));
    });

    test('successful log request', () async {});

    test('download param sends content disposition header', () async {
      final FakeHttpRequest request = FakeHttpRequest(
          uri: Uri(
        path: '/public/get-log',
        queryParameters: <String, String>{
          GetLog.ownerKeyParam: 'owner123',
          GetLog.downloadParam: 'true',
        },
      ));
      final ApiRequestHandlerTester tester = ApiRequestHandlerTester()
        ..request = request;

      await tester.get(handler);
      
      expect(request.response.headers.value('Content-Disposition'), '');
    });
  });
}
