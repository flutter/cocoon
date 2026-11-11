// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/want_lgtm_state.dart';
import 'package:cocoon_service/src/request_handlers/vacuum_want_lgtm.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:cocoon_service/src/service/flags/want_lgtm_flags.dart';
import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/request_handling/api_request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late ApiRequestHandlerTester tester;
  late FakeFirestoreService firestore;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late VacuumWantLgtm handler;

  final flutterSlug = RepositorySlug('flutter', 'flutter');
  final cocoonSlug = RepositorySlug('flutter', 'cocoon');

  Future<Map<String, Object?>> decodeBody(
    Stream<List<int>> responseBody,
  ) async {
    final raw = await utf8.decodeStream(responseBody);
    return jsonDecode(raw) as Map<String, Object?>;
  }

  setUp(() {
    firestore = FakeFirestoreService();
    mockGithubChecksUtil = MockGithubChecksUtil();
    config = FakeConfig(
      supportedReposValue: {flutterSlug, cocoonSlug},
      dynamicConfig: DynamicConfig(
        wantLgtm: WantLgtmFlags(
          enabled: true,
          useForAllRepos: false,
          enabledRepos: ['flutter/cocoon'],
        ),
      ),
    );
    tester = ApiRequestHandlerTester();
    handler = VacuumWantLgtm(
      config: config,
      authenticationProvider: FakeDashboardAuthentication(),
      firestore: firestore,
      githubChecksUtil: mockGithubChecksUtil,
    );

    when(
      mockGithubChecksUtil.updateCheckRun(
        any,
        any,
        any,
        status: anyNamed('status'),
        conclusion: anyNamed('conclusion'),
        detailsUrl: anyNamed('detailsUrl'),
        output: anyNamed('output'),
      ),
    ).thenAnswer((_) async {});
  });

  test(
    'sweeps disabled repo in_progress runs and skips enabled and closed states',
    () async {
      firestore.putDocuments([
        WantLgtmState.initialize(
          slug: flutterSlug,
          pr: 101,
          headSha: 'sha_flutter',
          checkRunId: 7001,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on alice',
        ),
        WantLgtmState.initialize(
          slug: flutterSlug,
          pr: 102,
          headSha: 'sha_closed',
          checkRunId: 7003,
          checkRunStatus: 'closed',
          checkRunTitle: 'Waiting on carol',
        ),
        WantLgtmState.initialize(
          slug: cocoonSlug,
          pr: 202,
          headSha: 'sha_cocoon',
          checkRunId: 7002,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on bob',
        ),
      ]);

      final response = await tester.get(handler);
      expect(response.statusCode, 200);
      expect(await decodeBody(response.body), {'swept': 1, 'dry_run': false});

      final flutterState = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: firestore,
        slug: flutterSlug,
        pr: 101,
      );
      expect(flutterState?.checkRunStatus, 'completed');
      expect(flutterState?.checkRunConclusion, 'neutral');

      final closedState = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: firestore,
        slug: flutterSlug,
        pr: 102,
      );
      expect(closedState?.checkRunStatus, 'closed');

      final cocoonState = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: firestore,
        slug: cocoonSlug,
        pr: 202,
      );
      expect(cocoonState?.checkRunStatus, 'in_progress');
      expect(cocoonState?.checkRunConclusion, isNull);

      verify(
        mockGithubChecksUtil.updateCheckRun(
          config,
          flutterSlug,
          argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 7001)),
          status: github.CheckRunStatus.completed,
          conclusion: github.CheckRunConclusion.neutral,
          detailsUrl: 'https://github.com/flutter/flutter/pull/101',
          output: anyNamed('output'),
        ),
      ).called(1);
    },
  );

  test('returns 0 without querying when useForAllRepos is enabled', () async {
    config.dynamicConfig = DynamicConfig(
      wantLgtm: WantLgtmFlags(enabled: true, useForAllRepos: true),
    );
    firestore.putDocument(
      WantLgtmState.initialize(
        slug: flutterSlug,
        pr: 101,
        headSha: 'sha_flutter',
        checkRunId: 7001,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on alice',
      ),
    );

    final response = await tester.get(handler);
    expect(response.statusCode, 200);
    expect(await decodeBody(response.body), {'swept': 0, 'dry_run': false});
    verifyZeroInteractions(mockGithubChecksUtil);
  });

  test('supports dry_run=true without mutating GitHub or Firestore', () async {
    firestore.putDocument(
      WantLgtmState.initialize(
        slug: flutterSlug,
        pr: 101,
        headSha: 'sha_flutter',
        checkRunId: 7001,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on alice',
      ),
    );

    tester.request.uri = tester.request.uri.replace(
      queryParameters: {'dry_run': 'true'},
    );

    final response = await tester.get(handler);
    expect(response.statusCode, 200);
    expect(await decodeBody(response.body), {'swept': 1, 'dry_run': true});

    verifyNever(
      mockGithubChecksUtil.updateCheckRun(
        any,
        any,
        any,
        status: anyNamed('status'),
        conclusion: anyNamed('conclusion'),
        detailsUrl: anyNamed('detailsUrl'),
        output: anyNamed('output'),
      ),
    );

    final flutterState = await WantLgtmState.fromFirestoreOrNull(
      firestoreService: firestore,
      slug: flutterSlug,
      pr: 101,
    );
    expect(flutterState?.checkRunStatus, 'in_progress');
  });

  test(
    'continues sweeping remaining PRs when one check run update fails',
    () async {
      when(
        mockGithubChecksUtil.updateCheckRun(
          any,
          any,
          argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 7001)),
          status: anyNamed('status'),
          conclusion: anyNamed('conclusion'),
          detailsUrl: anyNamed('detailsUrl'),
          output: anyNamed('output'),
        ),
      ).thenThrow(Exception('GitHub 502 Bad Gateway'));

      firestore.putDocuments([
        WantLgtmState.initialize(
          slug: flutterSlug,
          pr: 101,
          headSha: 'sha_101',
          checkRunId: 7001,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on alice',
        ),
        WantLgtmState.initialize(
          slug: flutterSlug,
          pr: 102,
          headSha: 'sha_102',
          checkRunId: 7002,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on bob',
        ),
      ]);

      final response = await tester.get(handler);
      expect(response.statusCode, 200);
      expect(await decodeBody(response.body), {'swept': 2, 'dry_run': false});

      final failedState = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: firestore,
        slug: flutterSlug,
        pr: 101,
      );
      expect(failedState?.checkRunStatus, 'in_progress');

      final succeededState = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: firestore,
        slug: flutterSlug,
        pr: 102,
      );
      expect(succeededState?.checkRunStatus, 'completed');
      expect(succeededState?.checkRunConclusion, 'neutral');
    },
  );
}
