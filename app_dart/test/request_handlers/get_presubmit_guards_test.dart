// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handlers/get_presubmit_guards.dart';
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
  late GetPresubmitGuards handler;
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
    handler = GetPresubmitGuards(
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
        GetPresubmitGuards.kRepoParam: 'flutter',
        GetPresubmitGuards.kPRParam: '123',
      },
    );

    final response = await tester.get(handler);
    expect(response.statusCode, HttpStatus.notFound);
  });

  test('returns multiple guards grouped by commitSha', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const prNumber = 123;

    // SHA1: Two stages, both succeeded.
    final guard1a = generatePresubmitGuard(
      slug: slug,
      pullRequestId: prNumber,
      commitSha: 'sha1',
      checkRun: generateCheckRun(1),
      creationTime: 100,
      builds: {'test1': TaskStatus.succeeded},
    );
    guard1a.failedBuilds = 0;
    guard1a.remainingBuilds = 0;

    final guard1b = generatePresubmitGuard(
      slug: slug,
      pullRequestId: prNumber,
      commitSha: 'sha1',
      checkRun: generateCheckRun(2),
      creationTime: 110,
      builds: {'test2': TaskStatus.succeeded},
    );
    guard1b.failedBuilds = 0;
    guard1b.remainingBuilds = 0;

    // SHA2: One stage, failed.
    final guard2 = generatePresubmitGuard(
      slug: slug,
      pullRequestId: prNumber,
      commitSha: 'sha2',
      checkRun: generateCheckRun(3),
      creationTime: 200,
      builds: {'test3': TaskStatus.failed},
    );
    guard2.failedBuilds = 1;
    guard2.remainingBuilds = 0;

    firestore.putDocuments([guard1a, guard1b, guard2]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuards.kRepoParam: 'flutter',
        GetPresubmitGuards.kPRParam: prNumber.toString(),
      },
    );

    final result = (await getResponse())!;
    expect(result.length, 2);

    final item1 = result.firstWhere((g) => g.commitSha == 'sha1');
    expect(item1.creationTime, 110); // latest
    expect(item1.guardStatus, GuardStatus.succeeded);

    final item2 = result.firstWhere((g) => g.commitSha == 'sha2');
    expect(item2.creationTime, 200);
    expect(item2.guardStatus, GuardStatus.failed);
  });
}
