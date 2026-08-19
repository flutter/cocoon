// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:github/github.dart' as github;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('GithubChecksUtil', () {
    late GithubChecksUtil githubChecksUtil;
    late MockGitHub mockGitHub;
    late MockChecksService mockChecksService;
    late MockCheckRunsService mockCheckRunsService;
    late FakeConfig config;
    late github.RepositorySlug slug;

    setUp(() {
      githubChecksUtil = const GithubChecksUtil();
      mockGitHub = MockGitHub();
      mockChecksService = MockChecksService();
      mockCheckRunsService = MockCheckRunsService();
      when(mockGitHub.checks).thenReturn(mockChecksService);
      when(mockChecksService.checkRuns).thenReturn(mockCheckRunsService);
      config = FakeConfig(githubClient: mockGitHub);
      slug = github.RepositorySlug('flutter', 'flutter');
    });

    test('updateCheckRun calls checkRuns.updateCheckRun', () async {
      final checkRun = github.CheckRun.fromJson(
        jsonDecode(
              '{"name": "Guard", "id": 1234, "status": "completed", "conclusion": "failure", "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 1}}',
            )
            as Map<String, dynamic>,
      );

      when(
        mockCheckRunsService.updateCheckRun(
          slug,
          checkRun,
          status: anyNamed('status'),
          conclusion: anyNamed('conclusion'),
          detailsUrl: anyNamed('detailsUrl'),
          output: anyNamed('output'),
          actions: anyNamed('actions'),
        ),
      ).thenAnswer((_) async => checkRun);

      await githubChecksUtil.updateCheckRun(
        config,
        slug,
        checkRun,
        status: github.CheckRunStatus.inProgress,
        conclusion: github.CheckRunConclusion.neutral,
        detailsUrl: 'https://example.com/details',
      );

      verify(
        mockCheckRunsService.updateCheckRun(
          slug,
          checkRun,
          status: github.CheckRunStatus.inProgress,
          conclusion: github.CheckRunConclusion.neutral,
          detailsUrl: 'https://example.com/details',
        ),
      ).called(1);
    });
  });
}
