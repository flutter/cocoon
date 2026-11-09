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
    'sweeps disabled repo in_progress runs and skips enabled repo',
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

  test('filters sweep by specific repo query parameter', () async {
    final packagesSlug = RepositorySlug('flutter', 'packages');
    config.supportedReposValue = {flutterSlug, packagesSlug, cocoonSlug};

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
        slug: packagesSlug,
        pr: 303,
        headSha: 'sha_packages',
        checkRunId: 7003,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on carol',
      ),
    ]);

    tester.request.uri = tester.request.uri.replace(
      queryParameters: {'repo': 'flutter/flutter'},
    );

    final response = await tester.get(handler);
    expect(response.statusCode, 200);
    expect(await decodeBody(response.body), {
      'swept': 1,
      'dry_run': false,
      'repo': 'flutter/flutter',
    });

    final packagesState = await WantLgtmState.fromFirestoreOrNull(
      firestoreService: firestore,
      slug: packagesSlug,
      pr: 303,
    );
    expect(packagesState?.checkRunStatus, 'in_progress');
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

  test('returns 404 for unsupported repo', () async {
    tester.request.uri = tester.request.uri.replace(
      queryParameters: {'repo': 'flutter/unknown'},
    );

    final response = await tester.get(handler);
    expect(response.statusCode, 404);
    expect(await decodeBody(response.body), {
      'error': 'repo not found: flutter/unknown',
    });
  });

  test('returns 400 for malformed repo parameter', () async {
    tester.request.uri = tester.request.uri.replace(
      queryParameters: {'repo': 'invalid-slug'},
    );

    final response = await tester.get(handler);
    expect(response.statusCode, 400);
    expect(await decodeBody(response.body), {
      'error': 'Invalid repo parameter: invalid-slug',
    });
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
      expect(await decodeBody(response.body), {'swept': 1, 'dry_run': false});

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
