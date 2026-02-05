// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/request_handlers/get_presubmit_guard.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late GetPresubmitGuard handler;
  late FakeFirestoreService firestore;

  Future<T?> decodeHandlerBody<T>() async {
    final body = await tester.get(handler);
    return await utf8.decoder
            .bind(body.body as Stream<List<int>>)
            .transform(json.decoder)
            .single
        as T?;
  }

  setUp(() {
    firestore = FakeFirestoreService();
    tester = RequestHandlerTester();
    handler = GetPresubmitGuard(
      config: FakeConfig(),
      authenticationProvider: FakeDashboardAuthentication(),
      firestore: firestore,
    );
  });

  test('missing parameters', () async {
    tester.request = FakeHttpRequest();
    expect(tester.get(handler), throwsA(isA<BadRequestException>()));
  });

  test('no guards found', () async {
    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kSlugParam: 'flutter/flutter',
        GetPresubmitGuard.kShaParam: 'abc',
      },
    );

    final result = await decodeHandlerBody<Object?>();
    expect(result, isNull);
  });

  test('consolidates multiple stages', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final guard1 = generatePresubmitGuard(
      slug: slug,
      commitSha: sha,
      stage: CiStage.fusionTests,
      builds: {'test1': TaskStatus.succeeded},
    );
    guard1.failedBuilds = 0;
    guard1.remainingBuilds = 0;

    final guard2 = generatePresubmitGuard(
      slug: slug,
      commitSha: sha,
      stage: CiStage.fusionEngineBuild,
      builds: {'engine1': TaskStatus.inProgress},
    );
    guard2.failedBuilds = 0;
    guard2.remainingBuilds = 1;

    firestore.putDocuments([guard1, guard2]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kSlugParam: 'flutter/flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await decodeHandlerBody<Map<String, Object?>>())!;
    expect(result['pr_num'], 123);
    expect(result['author'], 'dash');
    expect(result['check_run_id'], 1);
    expect(result['guard_status'], 'In Progress');

    final stages = result['stages'] as List<Object?>;
    expect(stages.length, 2);

    final fusionStage = stages.firstWhere((s) => (s as Map)['name'] == 'fusion') as Map;
    expect(fusionStage['builds'], {'test1': 'Succeeded'});

    final engineStage = stages.firstWhere((s) => (s as Map)['name'] == 'engine') as Map;
    expect(engineStage['builds'], {'engine1': 'In Progress'});
  });

  test('guardStatus is Failed if any stage has failed builds', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';
    
    final guard = generatePresubmitGuard(
      slug: slug,
      commitSha: sha,
      builds: {'test1': TaskStatus.failed},
    );
    guard.failedBuilds = 1;
    guard.remainingBuilds = 0;

    firestore.putDocuments([guard]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kSlugParam: 'flutter/flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await decodeHandlerBody<Map<String, Object?>>())!;
    expect(result['guard_status'], 'Failed');
  });

  test('guardStatus is Succeeded if all stages are complete without failures', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final guard = generatePresubmitGuard(
      slug: slug,
      commitSha: sha,
      builds: {'test1': TaskStatus.succeeded},
    );
    guard.failedBuilds = 0;
    guard.remainingBuilds = 0;

    firestore.putDocuments([guard]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kSlugParam: 'flutter/flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await decodeHandlerBody<Map<String, Object?>>())!;
    expect(result['guard_status'], 'Succeeded');
  });

  test('guardStatus is New if all stages are waiting for backfill', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const sha = 'abc';

    final guard = generatePresubmitGuard(
      slug: slug,
      commitSha: sha,
      builds: {'test1': TaskStatus.waitingForBackfill},
    );
    guard.failedBuilds = 0;
    guard.remainingBuilds = 1;

    firestore.putDocuments([guard]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuard.kSlugParam: 'flutter/flutter',
        GetPresubmitGuard.kShaParam: sha,
      },
    );

    final result = (await decodeHandlerBody<Map<String, Object?>>())!;
    expect(result['guard_status'], 'New');
  });
}
