// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/src/rpc_model/presubmit_guard.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/request_handlers/get_presubmit_guard.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:test/test.dart';

import '../src/request_handling/request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late GetPresubmitGuard handler;
  late FakeFirestoreService firestore;

  Future<PresubmitGuardResponse?> getResponse() async {
    final response = await tester.get(handler);
    if (response.statusCode != HttpStatus.ok) {
      return null;
    }
    final responseBody = await utf8.decoder
        .bind(response.body as Stream<List<int>>)
        .transform(json.decoder)
        .single;
    if (responseBody == null) {
      return null;
    }
    return PresubmitGuardResponse.fromJson(
      responseBody as Map<String, Object?>,
    );
  }

  setUp(() {
    firestore = FakeFirestoreService();
    tester = RequestHandlerTester();
    handler = GetPresubmitGuard(config: FakeConfig(), firestore: firestore);
  });

  test('missing parameters', () async {
    tester.request = FakeHttpRequest();
    expect(tester.get(handler), throwsA(isA<BadRequestException>()));
  });

  test('no guards found', () async {
    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kOwnerParam: 'flutter',
        GetPresubmitGuard.kRepoParam: 'flutter',
        GetPresubmitGuard.kShaParam: 'abc',
      },
    );

    final result = await getResponse();
    expect(result, isNull);
  });

  test('consolidates multiple stages', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final guard1 = generatePresubmitGuard(
      slug: slug,
      headSha: sha,
      stage: CiStage.fusionTests,
      jobs: {'test1': TaskStatus.succeeded},
      remainingJobs: 0,
    );

    final guard2 = generatePresubmitGuard(
      slug: slug,
      headSha: sha,
      stage: CiStage.fusionEngineBuild,
      jobs: {'engine1': TaskStatus.inProgress},
    );

    firestore.putDocuments([guard1, guard2]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kOwnerParam: 'flutter',
        GetPresubmitGuard.kRepoParam: 'flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await getResponse())!;
    expect(result.prNum, 123);
    expect(result.author, 'dash');
    expect(result.checkRunId, 1);
    expect(result.guardStatus, GuardStatus.inProgress);

    final stages = result.stages;
    expect(stages.length, 2);

    final fusionStage = stages.firstWhere((s) => s.name == 'fusion');
    expect(fusionStage.jobs, {'test1': TaskStatus.succeeded});

    final engineStage = stages.firstWhere((s) => s.name == 'engine');
    expect(engineStage.jobs, {'engine1': TaskStatus.inProgress});
  });

  test('guardStatus is Failed if any stage has failed builds', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final guard = generatePresubmitGuard(
      slug: slug,
      headSha: sha,
      jobs: {'test1': TaskStatus.failed},
      failedJobs: 1,
      remainingJobs: 0,
    );

    firestore.putDocuments([guard]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kOwnerParam: 'flutter',
        GetPresubmitGuard.kRepoParam: 'flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await getResponse())!;
    expect(result.guardStatus, GuardStatus.failed);
  });

  test(
    'guardStatus is Succeeded if all stages are complete without failures',
    () async {
      final slug = RepositorySlug('flutter', 'flutter');
      const sha = 'abc';

      final guard = generatePresubmitGuard(
        slug: slug,
        headSha: sha,
        jobs: {'test1': TaskStatus.succeeded},
        remainingJobs: 0,
      );

      firestore.putDocuments([guard]);

      tester.request = FakeHttpRequest(
        queryParametersValue: {
          GetPresubmitGuard.kOwnerParam: 'flutter',
          GetPresubmitGuard.kRepoParam: 'flutter',
          GetPresubmitGuard.kShaParam: sha,
        },
      );

      final result = (await getResponse())!;
      expect(result.guardStatus, GuardStatus.succeeded);
    },
  );

  test('guardStatus is New if all stages are waiting for backfill', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final guard = generatePresubmitGuard(
      slug: slug,
      headSha: sha,
      jobs: {'test1': TaskStatus.waitingForBackfill},
    );

    firestore.putDocuments([guard]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kOwnerParam: 'flutter',
        GetPresubmitGuard.kRepoParam: 'flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await getResponse())!;
    expect(result.guardStatus, GuardStatus.waitingForBackfill);
  });

  test('is accessible without authentication', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final guard = generatePresubmitGuard(
      slug: slug,
      headSha: sha,
      jobs: {'test1': TaskStatus.succeeded},
      remainingJobs: 0,
    );

    firestore.putDocuments([guard]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kOwnerParam: 'flutter',
        GetPresubmitGuard.kRepoParam: 'flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final response = await tester.get(handler);
    expect(response.statusCode, HttpStatus.ok);
  });

  test('falls back to ciStaging if no guards found', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final staging = CiStaging.fromDocument(
      Document(
        name: CiStaging.documentNameFor(
          slug: slug,
          sha: sha,
          stage: CiStage.fusionEngineBuild,
        ),
        fields: {
          CiStaging.kTotalField: 2.toValue(),
          CiStaging.kRemainingField: 1.toValue(),
          CiStaging.kFailedField: 0.toValue(),
          CiStaging.kCheckRunGuardField: '{"id": 0}'.toValue(),
          CiStaging.fieldRepoFullPath: slug.fullName.toValue(),
          CiStaging.fieldCommitSha: sha.toValue(),
          CiStaging.fieldStage: CiStage.fusionEngineBuild.name.toValue(),
          'job1': TaskConclusion.success.name.toValue(),
          'job2': TaskConclusion.scheduled.name.toValue(),
        },
      ),
    );

    firestore.putDocuments([staging]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kOwnerParam: 'flutter',
        GetPresubmitGuard.kRepoParam: 'flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await getResponse())!;
    expect(result.prNum, 0);
    expect(result.checkRunId, 0);
    expect(result.guardStatus, GuardStatus.inProgress);
    expect(result.stages.length, 1);
    expect(result.stages.first.name, CiStage.fusionEngineBuild.name);
    expect(result.stages.first.jobs, {
      'job1': TaskStatus.succeeded,
      'job2': TaskStatus.waitingForBackfill,
    });
  });

  test(
    'falls back to queryAllTasksForCommit when both unified guards and ciStaging are empty',
    () async {
      const sha = 'abc';

      final task1 = generateFirestoreTask(
        1,
        name: 'task1',
        status: TaskStatus.succeeded,
        commitSha: sha,
        created: DateTime.fromMillisecondsSinceEpoch(100),
      );
      final task2 = generateFirestoreTask(
        2,
        name: 'task2',
        status: TaskStatus.inProgress,
        commitSha: sha,
        created: DateTime.fromMillisecondsSinceEpoch(200),
      );

      firestore.putDocuments([task1, task2]);

      tester.request = FakeHttpRequest(
        queryParametersValue: {
          GetPresubmitGuard.kOwnerParam: 'flutter',
          GetPresubmitGuard.kRepoParam: 'flutter',
          GetPresubmitGuard.kShaParam: sha,
        },
      );

      final result = (await getResponse())!;
      expect(result.prNum, 0);
      expect(result.checkRunId, -1);
      expect(result.guardStatus, GuardStatus.inProgress);
      expect(result.stages.length, 1);
      expect(result.stages.first.name, 'tasks');
      expect(result.stages.first.createdAt, 100);
      expect(result.stages.first.jobs, {
        'task1': TaskStatus.succeeded,
        'task2': TaskStatus.inProgress,
      });
    },
  );

  test(
    'blends ciStaging with tasks collection (no overlap in production)',
    () async {
      final slug = RepositorySlug('flutter', 'flutter');
      const sha = 'abc';

      // Note: In production, there is no overlap between the engine builds in ciStaging
      // and the post-submit tasks in the tasks collection.
      final staging = CiStaging.fromDocument(
        Document(
          name: CiStaging.documentNameFor(
            slug: slug,
            sha: sha,
            stage: CiStage.fusionEngineBuild,
          ),
          fields: {
            CiStaging.kTotalField: 2.toValue(),
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kFailedField: 0.toValue(),
            CiStaging.kCheckRunGuardField: '{"id": 0}'.toValue(),
            CiStaging.fieldRepoFullPath: slug.fullName.toValue(),
            CiStaging.fieldCommitSha: sha.toValue(),
            CiStaging.fieldStage: CiStage.fusionEngineBuild.name.toValue(),
            'job1': TaskConclusion.success.name.toValue(),
            'job2': TaskConclusion.scheduled.name.toValue(),
          },
        ),
      );

      final task1 = generateFirestoreTask(
        1,
        name: 'postSubmitJob1',
        status: TaskStatus.succeeded,
        commitSha: sha,
        created: DateTime.fromMillisecondsSinceEpoch(100),
      );
      final task2 = generateFirestoreTask(
        2,
        name: 'postSubmitJob2',
        status: TaskStatus.inProgress,
        commitSha: sha,
        created: DateTime.fromMillisecondsSinceEpoch(150),
      );

      firestore.putDocuments([staging, task1, task2]);

      tester.request = FakeHttpRequest(
        queryParametersValue: {
          GetPresubmitGuard.kOwnerParam: 'flutter',
          GetPresubmitGuard.kRepoParam: 'flutter',
          GetPresubmitGuard.kShaParam: sha,
        },
      );

      final result = (await getResponse())!;
      expect(result.prNum, 0);
      expect(result.checkRunId, 0);
      expect(result.guardStatus, GuardStatus.inProgress);
      expect(result.stages.length, 2);

      final engineStage = result.stages.firstWhere(
        (s) => s.name == CiStage.fusionEngineBuild.name,
      );
      expect(engineStage.jobs, {
        'job1': TaskStatus.succeeded,
        'job2': TaskStatus.waitingForBackfill,
      });

      final tasksStage = result.stages.firstWhere((s) => s.name == 'tasks');
      expect(tasksStage.jobs, {
        'postSubmitJob1': TaskStatus.succeeded,
        'postSubmitJob2': TaskStatus.inProgress,
      });
      expect(tasksStage.createdAt, 100);
    },
  );

  test(
    'correctly handles task reruns within tasks collection by adjusting counts and status transitions',
    () async {
      const sha = 'abc';

      // Note: In production, task reruns and attempts are processed purely within the tasks collection.
      // We simulate multiple attempts of 'task1' and 'task2' here.

      // Attempt 1 of task1 fails.
      final task1Attempt1 = generateFirestoreTask(
        1,
        name: 'task1',
        status: TaskStatus.failed,
        commitSha: sha,
        attempts: 1,
        created: DateTime.fromMillisecondsSinceEpoch(100),
      );

      // Attempt 2 of task1 is in progress. This should transition task1 from failed -> in progress.
      final task1Attempt2 = generateFirestoreTask(
        2,
        name: 'task1',
        status: TaskStatus.inProgress,
        commitSha: sha,
        attempts: 2,
        created: DateTime.fromMillisecondsSinceEpoch(200),
      );

      // task2 succeeds.
      final task2 = generateFirestoreTask(
        3,
        name: 'task2',
        status: TaskStatus.succeeded,
        commitSha: sha,
        created: DateTime.fromMillisecondsSinceEpoch(300),
      );

      firestore.putDocuments([task1Attempt1, task1Attempt2, task2]);

      tester.request = FakeHttpRequest(
        queryParametersValue: {
          GetPresubmitGuard.kOwnerParam: 'flutter',
          GetPresubmitGuard.kRepoParam: 'flutter',
          GetPresubmitGuard.kShaParam: sha,
        },
      );

      final result = (await getResponse())!;
      expect(result.prNum, 0);
      expect(result.guardStatus, GuardStatus.inProgress);
      expect(result.stages.length, 1);

      final tasksStage = result.stages.first;
      expect(tasksStage.jobs, {
        'task1': TaskStatus.inProgress,
        'task2': TaskStatus.succeeded,
      });
      expect(tasksStage.createdAt, 100);
    },
  );

  test(
    'tasks with bringup true do not count towards guardStatus calculations',
    () async {
      const sha = 'abc';

      final taskBringup = generateFirestoreTask(
        1,
        name: 'bringup_task',
        status: TaskStatus.failed,
        commitSha: sha,
        bringup: true,
        created: DateTime.fromMillisecondsSinceEpoch(100),
      );
      final otherTask = generateFirestoreTask(
        1,
        name: 'succeeds',
        status: TaskStatus.succeeded,
        commitSha: sha,
        bringup: false,
        created: DateTime.fromMillisecondsSinceEpoch(100),
      );

      firestore.putDocuments([taskBringup, otherTask]);

      tester.request = FakeHttpRequest(
        queryParametersValue: {
          GetPresubmitGuard.kOwnerParam: 'flutter',
          GetPresubmitGuard.kRepoParam: 'flutter',
          GetPresubmitGuard.kShaParam: sha,
        },
      );

      final result = (await getResponse())!;
      expect(result.prNum, 0);
      // Since bringup_task is failed but has bringup: true, it does not affect overall status.
      // With 0 non-bringup builds, guardStatus remains Succeeded.
      expect(result.guardStatus, GuardStatus.succeeded);
      expect(result.stages.length, 1);

      final tasksStage = result.stages.first;
      expect(tasksStage.jobs, {
        'bringup_task': TaskStatus.failed,
        'succeeds': TaskStatus.succeeded,
      });
      expect(tasksStage.createdAt, 100);
    },
  );
}
