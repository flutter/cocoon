// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/request_handling/subscription_tester.dart';

void main() {
  useTestLoggerPerTest();

  late PresubmitGuardUpdateSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late FakeFirestoreService firestore;
  late CacheService cache;

  setUp(() {
    firestore = FakeFirestoreService();
    config = FakeConfig();
    cache = CacheService.inMemory();

    handler = PresubmitGuardUpdateSubscription(
      cache: cache,
      config: config,
      scheduler: FakeScheduler(
        config: config,
        firestore: firestore,
        bigQuery: MockBigQueryService(),
        cache: cache,
      ),
    );

    request = FakeHttpRequest();
    tester = SubscriptionTester(request: request);
  });

  test('returns emptyOk when message data is null', () async {
    tester.message = const PushMessage(data: null);
    await tester.post(handler);
  });

  test('skips update when guard is not marked dirty in cache', () async {
    const guardName =
        'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/flutter_flutter_123_456_fusionTests';
    tester.message = PushMessage(
      data: jsonEncode({'guard_document_name': guardName}),
    );

    await tester.post(handler);
  });

  test('updates PresubmitGuard with latest jobs when dirty in cache', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const prNum = 123;
    const checkRunId = 456;
    const stage = CiStage.fusionTests;

    final guard =
        generatePresubmitGuard(
            slug: slug,
            prNum: prNum,
            stage: stage,
            checkRun: generateCheckRun(checkRunId),
            remainingJobs: 2,
            failedJobs: 0,
            jobs: {
              'linux_test': TaskStatus.waitingForBackfill,
              'mac_test': TaskStatus.waitingForBackfill,
            },
          )
          ..name = PresubmitGuard.documentNameFor(
            slug: slug,
            prNum: prNum,
            checkRunId: checkRunId,
            stage: stage,
          );
    await firestore.writeViaTransaction(
      documentsToWrites([guard], exists: false),
    );

    final job1 =
        PresubmitJob(
            slug: slug,
            checkRunId: checkRunId,
            jobName: 'linux_test',
            status: TaskStatus.succeeded,
            attemptNumber: 1,
            creationTime: 1000,
          )
          ..name = PresubmitJob.documentNameFor(
            slug: slug,
            checkRunId: checkRunId,
            jobName: 'linux_test',
            attemptNumber: 1,
          );
    final job2 =
        PresubmitJob(
            slug: slug,
            checkRunId: checkRunId,
            jobName: 'mac_test',
            status: TaskStatus.inProgress,
            attemptNumber: 1,
            creationTime: 1000,
          )
          ..name = PresubmitJob.documentNameFor(
            slug: slug,
            checkRunId: checkRunId,
            jobName: 'mac_test',
            attemptNumber: 1,
          );
    await firestore.writeViaTransaction(
      documentsToWrites([job1, job2], exists: false),
    );

    final guardName = guard.name!;
    await cache.set(
      'presubmit_guard_dirty',
      guardName,
      Uint8List.fromList([1]),
    );

    tester.message = PushMessage(
      data: jsonEncode({'guard_document_name': guardName}),
    );

    await tester.post(handler);

    final updatedDoc = await firestore.getDocument(guardName);
    final updatedGuard = PresubmitGuard.fromDocument(updatedDoc);

    expect(updatedGuard.remainingJobs, 1);
    expect(updatedGuard.failedJobs, 0);
    expect(updatedGuard.jobs['linux_test'], TaskStatus.succeeded);
    expect(updatedGuard.jobs['mac_test'], TaskStatus.inProgress);
    expect(await cache.get('presubmit_guard_dirty', guardName), isNull);
  });
}
