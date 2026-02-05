// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_check.dart' as fs;
import 'package:cocoon_service/src/request_handlers/get_presubmit_checks.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  group('GetPresubmitChecks', () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late GetPresubmitChecks handler;
    late FakeFirestoreService firestoreService;

    setUp(() {
      config = FakeConfig();
      tester = RequestHandlerTester();
      firestoreService = FakeFirestoreService();
      handler = GetPresubmitChecks(
        config: config,
        firestore: firestoreService,
      );
    });

    Future<T?> decodeHandlerBody<T>(Response response) async {
      return await utf8.decoder
              .bind(response.body)
              .transform(json.decoder)
              .single
          as T?;
    }

    test('returns 400 when parameters are missing', () async {
      tester.request = FakeHttpRequest();
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('returns 400 when check_run_id is not an integer', () async {
      tester.request = FakeHttpRequest(
        queryParametersValue: {
          'check_run_id': 'abc',
          'build_name': 'linux',
        },
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('returns 404 when no attempts found', () async {
      tester.request = FakeHttpRequest(
        queryParametersValue: {
          'check_run_id': '123',
          'build_name': 'linux',
        },
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.notFound);
    });

    test('returns attempts when found', () async {
      final check = fs.PresubmitCheck(
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 100,
        startTime: 110,
        endTime: 120,
        summary: 'all good',
      );
      await firestoreService.writeViaTransaction(
        documentsToWrites([check], exists: false),
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {
          'check_run_id': '123',
          'build_name': 'linux',
        },
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.ok);

      final jsonBody = (await decodeHandlerBody<List<dynamic>>(response))!;
      expect(jsonBody.length, 1);
      expect(jsonBody[0]['attempt_number'], 1);
      expect(jsonBody[0]['build_name'], 'linux');
      expect(jsonBody[0]['status'], 'Succeeded');
    });
  });
}
