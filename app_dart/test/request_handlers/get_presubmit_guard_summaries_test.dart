// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handlers/get_presubmit_guard_summaries.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/request_handling/request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late GetPresubmitGuardSummaries handler;
  late FakeFirestoreService firestore;

  Future<List<rpc_model.PresubmitGuardSummary>?> getResponse() async {
    final response = await tester.get(handler);
    if (response.statusCode != HttpStatus.ok) {
      return null;
    }
    final responseBody = await utf8.decoder
        .bind(response.body as Stream<List<int>>)
        .transform(json.decoder)
        .single;
    return (responseBody as List<dynamic>)
        .map(
          (e) => rpc_model.PresubmitGuardSummary.fromJson(
            e as Map<String, Object?>,
          ),
        )
        .toList();
  }

  setUp(() {
    firestore = FakeFirestoreService();
    tester = RequestHandlerTester();
    handler = GetPresubmitGuardSummaries(
      config: FakeConfig(),
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
        GetPresubmitGuardSummaries.kRepoParam: 'flutter',
        GetPresubmitGuardSummaries.kPRParam: '123',
      },
    );

    final response = await tester.get(handler);
    expect(response.statusCode, HttpStatus.notFound);
  });

  test('returns multiple guards grouped by commitSha', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const prNum = 123;

    // SHA1: Two stages, both succeeded.
    final guard1a = generatePresubmitGuard(
      slug: slug,
      prNum: prNum,
      headSha: 'sha1',
      checkRun: generateCheckRun(1),
      creationTime: 100,
      jobs: {'test1': TaskStatus.succeeded},
      remainingJobs: 0,
    );

    final guard1b = generatePresubmitGuard(
      slug: slug,
      prNum: prNum,
      headSha: 'sha1',
      checkRun: generateCheckRun(2),
      creationTime: 110,
      jobs: {'test2': TaskStatus.succeeded},
      remainingJobs: 0,
    );

    // SHA2: One stage, failed.
    final guard2 = generatePresubmitGuard(
      slug: slug,
      prNum: prNum,
      headSha: 'sha2',
      checkRun: generateCheckRun(3),
      creationTime: 200,
      jobs: {'test3': TaskStatus.failed},
      failedJobs: 1,
      remainingJobs: 0,
    );

    firestore.putDocuments([guard1a, guard1b, guard2]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuardSummaries.kRepoParam: 'flutter',
        GetPresubmitGuardSummaries.kPRParam: prNum.toString(),
      },
    );

    final result = (await getResponse())!;
    expect(result.length, 2);

    final item1 = result.firstWhere((g) => g.headSha == 'sha1');
    expect(item1.creationTime, 100); // earliest
    expect(item1.guardStatus, GuardStatus.succeeded);

    final item2 = result.firstWhere((g) => g.headSha == 'sha2');
    expect(item2.creationTime, 200);
    expect(item2.guardStatus, GuardStatus.failed);
  });

  test('is accessible without authentication', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const prNumber = 123;

    final guard = generatePresubmitGuard(
      slug: slug,
      prNum: prNumber,
      headSha: 'sha1',
      checkRun: generateCheckRun(1),
      creationTime: 100,
    );

    firestore.putDocuments([guard]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuardSummaries.kRepoParam: 'flutter',
        GetPresubmitGuardSummaries.kPRParam: prNumber.toString(),
      },
    );

    final response = await tester.get(handler);
    expect(response.statusCode, HttpStatus.ok);
  });
}
