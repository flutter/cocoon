// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_check.dart' as fs;
import 'package:cocoon_service/src/request_handlers/get_presubmit_checks.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('GetPresubmitChecks', () {
    useTestLoggerPerTest();
    late FakeConfig config;
    late RequestHandlerTester tester;
    late GetPresubmitChecks handler;
    late FakeFirestoreService firestoreService;

    setUp(() {
      config = FakeConfig();
      tester = RequestHandlerTester();
      firestoreService = FakeFirestoreService();
      handler = GetPresubmitChecks(config: config, firestore: firestoreService);
    });

    Future<List<PresubmitCheckResponse>?> getPresubmitCheckResponse(
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
          PresubmitCheckResponse.fromJson(item as Map<String, Object?>),
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

    test('returns 404 when no checks found', () async {
      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': '123', 'build_name': 'linux'},
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.notFound);
    });

    test('returns checks when found', () async {
      final check = fs.PresubmitCheck(
        slug: RepositorySlug('flutter', 'flutter'),
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
        documentsToWrites([check], exists: false),
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': '123', 'build_name': 'linux'},
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.ok);

      final checks = (await getPresubmitCheckResponse(response))!;
      expect(checks.length, 1);
      expect(checks[0].attemptNumber, 1);
      expect(checks[0].buildName, 'linux');
      expect(checks[0].status, 'Succeeded');
      expect(checks[0].buildNumber, 456);
    });

    test('returns checks when found with owner and repo', () async {
      final slug = RepositorySlug('flutter', 'cocoon');
      final check = fs.PresubmitCheck(
        slug: slug,
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 100,
      );
      await firestoreService.writeViaTransaction(
        documentsToWrites([check], exists: false),
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {
          'check_run_id': '123',
          'build_name': 'linux',
          'owner': 'flutter',
          'repo': 'cocoon',
        },
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.ok);

      final checks = (await getPresubmitCheckResponse(response))!;
      expect(checks.length, 1);
      expect(checks[0].attemptNumber, 1);
      expect(checks[0].buildName, 'linux');
    });

    test(
      'does not return checks from other repos when owner/repo specified',
      () async {
        final slug1 = RepositorySlug('flutter', 'flutter');
        final slug2 = RepositorySlug('flutter', 'cocoon');

        final check1 = fs.PresubmitCheck(
          slug: slug1,
          checkRunId: 123,
          buildName: 'linux',
          status: TaskStatus.succeeded,
          attemptNumber: 1,
          creationTime: 100,
        );
        final check2 = fs.PresubmitCheck(
          slug: slug2,
          checkRunId: 123,
          buildName: 'linux',
          status: TaskStatus.succeeded,
          attemptNumber: 1,
          creationTime: 100,
        );
        await firestoreService.writeViaTransaction(
          documentsToWrites([check1, check2], exists: false),
        );

        tester.request = FakeHttpRequest(
          queryParametersValue: {
            'check_run_id': '123',
            'build_name': 'linux',
            'owner': 'flutter',
            'repo': 'cocoon',
          },
        );
        final response = await tester.get(handler);
        expect(response.statusCode, HttpStatus.ok);

        final checks = (await getPresubmitCheckResponse(response))!;
        expect(checks.length, 1);
        expect(checks[0].buildName, 'linux');
        // We need to verify it's the right one.
        // Since we can't easily check fields of fs.PresubmitCheck from PresubmitCheckResponse
        // without more info, we'll rely on the handler logic using the slug.
      },
    );

    test('returns multiple checks in descending order', () async {
      final slug = RepositorySlug('flutter', 'flutter');
      final check1 = fs.PresubmitCheck(
        slug: slug,
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 100,
      );
      final check2 = fs.PresubmitCheck(
        slug: slug,
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.failed,
        attemptNumber: 2,
        creationTime: 200,
      );
      await firestoreService.writeViaTransaction(
        documentsToWrites([check1, check2], exists: false),
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': '123', 'build_name': 'linux'},
      );
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.ok);

      final checks = (await getPresubmitCheckResponse(response))!;
      expect(checks.length, 2);
      expect(checks[0].attemptNumber, 2);
      expect(checks[1].attemptNumber, 1);
    });

    test('is accessible without authentication', () async {
      final check = fs.PresubmitCheck(
        slug: RepositorySlug('flutter', 'flutter'),
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 100,
      );
      await firestoreService.writeViaTransaction(
        documentsToWrites([check], exists: false),
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {'check_run_id': '123', 'build_name': 'linux'},
      );
      // No auth context set on tester
      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.ok);
    });
  });
}
