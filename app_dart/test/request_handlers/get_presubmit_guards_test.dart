// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
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

  Future<List<dynamic>?> getResponse() async {
    final response = await tester.get(handler);
    if (response.statusCode != HttpStatus.ok) {
      return null;
    }
    final responseBody = await utf8.decoder
        .bind(response.body as Stream<List<int>>)
        .transform(json.decoder)
        .single;
    return responseBody as List<dynamic>?;
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

  test('returns multiple guards for a PR', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const prNumber = 123;

    final guard1 = generatePresubmitGuard(
      slug: slug,
      pullRequestId: prNumber,
      commitSha: 'sha1',
      checkRun: generateCheckRun(1),
      creationTime: 100,
      builds: {'test1': TaskStatus.succeeded},
    );
    guard1.failedBuilds = 0;
    guard1.remainingBuilds = 0;

    final guard2 = generatePresubmitGuard(
      slug: slug,
      pullRequestId: prNumber,
      commitSha: 'sha2',
      checkRun: generateCheckRun(2),
      creationTime: 200,
      builds: {'test2': TaskStatus.failed},
    );
    guard2.failedBuilds = 1;
    guard2.remainingBuilds = 0;

    firestore.putDocuments([guard1, guard2]);

    tester.request = FakeHttpRequest(
      queryParametersValue: {
        GetPresubmitGuards.kRepoParam: 'flutter',
        GetPresubmitGuards.kPRParam: prNumber.toString(),
      },
    );

    final result = (await getResponse())!;
    expect(result.length, 2);

    final item1 = result.firstWhere((g) => g['check_run_id'] == 1);
    expect(item1['commit_sha'], 'sha1');
    expect(item1['creation_time'], 100);
    expect(item1['guard_status'], GuardStatus.succeeded.value);

    final item2 = result.firstWhere((g) => g['check_run_id'] == 2);
    expect(item2['commit_sha'], 'sha2');
    expect(item2['creation_time'], 200);
    expect(item2['guard_status'], GuardStatus.failed.value);
  });
}
