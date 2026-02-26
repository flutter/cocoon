// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_job.dart' as fs;
import 'package:cocoon_service/src/request_handlers/get_presubmit_jobs.dart';
import 'package:test/test.dart';

import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('GetPresubmitJobs', () {
    useTestLoggerPerTest();
    late FakeConfig config;
    late RequestHandlerTester tester;
    late GetPresubmitJobs handler;
    late FakeFirestoreService firestoreService;

    setUp(() {
      config = FakeConfig();
      tester = RequestHandlerTester();
      firestoreService = FakeFirestoreService();
      handler = GetPresubmitJobs(
        config: config,
        firestore: firestoreService,
        authenticationProvider: FakeDashboardAuthentication(),
      );
    });

    Future<List<PresubmitJobResponse>?> getPresubmitJobResponse(
      Response response,
    ) async {
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final jsonBody =
          await utf8.decoder.bind(response.body).transform(json.decoder).single
              as List<dynamic>?;
      if (jsonBody == null) {
        return null;
      }
      return [
        for (final item in jsonBody)
          PresubmitJobResponse.fromJson(item as Map<String, Object?>),
      ];
    }

    test('returns 400 when parameters are missing', () async {
      tester.request = FakeHttpRequest();
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('returns 400 when check_run_id is not an integer', () async {
      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': 'abc', 'build_name': 'linux'},
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('returns 404 when no jobs found', () async {
      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': '123', 'build_name': 'linux'},
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.notFound);
    });

    test('returns jobs when found', () async {
      final job = fs.PresubmitJob(
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 100,
        startTime: 110,
        endTime: 120,
        summary: 'all good',
        buildNumber: 456,
      );
      await firestoreService.writeViaTransaction(
        documentsToWrites([job], exists: false),
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': '123', 'build_name': 'linux'},
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.ok);

      final jobs = (await getPresubmitJobResponse(response))!;
      expect(jobs.length, 1);
      expect(jobs[0].attemptNumber, 1);
      expect(jobs[0].buildName, 'linux');
      expect(jobs[0].status, 'Succeeded');
      expect(jobs[0].buildNumber, 456);
    });

    test('returns multiple jobs in descending order', () async {
      final job1 = fs.PresubmitJob(
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 100,
      );
      final job2 = fs.PresubmitJob(
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.failed,
        attemptNumber: 2,
        creationTime: 200,
      );
      await firestoreService.writeViaTransaction(
        documentsToWrites([job1, job2], exists: false),
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': '123', 'build_name': 'linux'},
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.ok);

      final jobs = (await getPresubmitJobResponse(response))!;
      expect(jobs.length, 2);
      expect(jobs[0].attemptNumber, 2);
      expect(jobs[1].attemptNumber, 1);
    });
  });
}
