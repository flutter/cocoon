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
}
