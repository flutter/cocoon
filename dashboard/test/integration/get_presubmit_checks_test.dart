// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_job.dart';
import 'package:flutter_dashboard/service/appengine_cocoon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github/github.dart';

void main() {
  group('Integration: Get Presubmit Checks', () {
    late IntegrationServer server;
    late IntegrationHttpClient client;
    late AppEngineCocoonService service;

    setUp(() async {
      server = IntegrationServer(
        config: FakeConfig(webhookKeyValue: 'fake-secret'),
      );
      client = IntegrationHttpClient(server);
      service = AppEngineCocoonService(client: client);
    });

    test('returns empty list when no checks exist', () async {
      final response = await service.fetchPresubmitJobDetails(
        checkRunId: 123,
        jobName: 'linux_android',
      );
      expect(response.error, isNotNull);
      expect(response.statusCode, 404);
    });

    test('returns presubmit check details', () async {
      final now = DateTime.now();
      final check = PresubmitJob(
        slug: RepositorySlug('flutter', 'flutter'),
        checkRunId: 456,
        jobName: 'linux android_2',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: now.millisecondsSinceEpoch,
        buildNumber: 1337,
        summary: 'Build succeeded',
        startTime: now.millisecondsSinceEpoch,
        endTime: now.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      );

      server.firestore.putDocuments([check]);

      final response = await service.fetchPresubmitJobDetails(
        checkRunId: 456,
        jobName: 'linux android_2',
      );

      expect(response.error, isNull);
      expect(response.data, hasLength(1));

      final result = response.data!.first;
      expect(result.jobName, 'linux android_2');
      expect(result.status, TaskStatus.succeeded);
      expect(result.attemptNumber, 1);
      expect(result.buildNumber, 1337);
      expect(result.summary, 'Build succeeded');
    });

    test('returns multiple attempts for same build', () async {
      final now = DateTime.now();
      final checkAttempt1 = PresubmitJob(
        slug: RepositorySlug('flutter', 'flutter'),
        checkRunId: 789,
        jobName: 'mac_ios',
        status: TaskStatus.failed,
        attemptNumber: 1,
        creationTime: now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        buildNumber: 1001,
        summary: 'Build failed',
      );

      final checkAttempt2 = PresubmitJob(
        slug: RepositorySlug('flutter', 'flutter'),
        checkRunId: 789,
        jobName: 'mac_ios',
        status: TaskStatus.succeeded,
        attemptNumber: 2,
        creationTime: now.millisecondsSinceEpoch,
        buildNumber: 1002,
        summary: 'Retry succeeded',
      );

      server.firestore.putDocuments([checkAttempt1, checkAttempt2]);

      final response = await service.fetchPresubmitJobDetails(
        checkRunId: 789,
        jobName: 'mac_ios',
      );

      expect(response.error, isNull);
      expect(response.data, hasLength(2));

      // Should be ordered by attempt number descending (default behavior of GetPresubmitJobsHandler)
      // I need to verify the order.
      // Based on `UnifiedCheckRun.getPresubmitJobDetails`:
      // `orderMap: const { PresubmitJob.fieldAttemptNumber: kQueryOrderDescending }`

      expect(response.data![0].attemptNumber, 2);
      expect(response.data![0].status, TaskStatus.succeeded);

      expect(response.data![1].attemptNumber, 1);
      expect(response.data![1].status, TaskStatus.failed);
    });
  });
}
