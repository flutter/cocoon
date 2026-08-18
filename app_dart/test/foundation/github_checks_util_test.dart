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
    late FakeConfig config;
    late github.RepositorySlug slug;

    setUp(() {
      githubChecksUtil = const GithubChecksUtil();
      mockGitHub = MockGitHub();
      config = FakeConfig(githubClient: mockGitHub);
      slug = github.RepositorySlug('flutter', 'flutter');
    });

    test(
      'resetCheckRun sends PATCH request with null conclusion and completed_at',
      () async {
        final checkRun = github.CheckRun.fromJson(
          jsonDecode(
                '{"name": "Guard", "id": 1234, "status": "completed", "conclusion": "failure", "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 1}}',
              )
              as Map<String, dynamic>,
        );

        when(
          // ignore: discarded_futures
          mockGitHub.requestJson<Map<String, dynamic>, github.CheckRun>(
            'PATCH',
            '/repos/flutter/flutter/check-runs/1234',
            statusCode: github.StatusCodes.OK,
            preview: 'application/vnd.github.antiope-preview+json',
            body: anyNamed('body'),
            convert: anyNamed('convert'),
          ),
        ).thenAnswer((_) async {
          return github.CheckRun.fromJson(
            jsonDecode(
                  '{"name": "Guard", "id": 1234, "status": "in_progress", "conclusion": null, "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 1}}',
                )
                as Map<String, dynamic>,
          );
        });

        await githubChecksUtil.resetCheckRun(
          config,
          slug,
          checkRun,
          status: github.CheckRunStatus.inProgress,
          detailsUrl: 'https://example.com/details',
        );

        final captured = verify(
          mockGitHub.requestJson<Map<String, dynamic>, github.CheckRun>(
            'PATCH',
            '/repos/flutter/flutter/check-runs/1234',
            statusCode: github.StatusCodes.OK,
            preview: 'application/vnd.github.antiope-preview+json',
            body: captureAnyNamed('body'),
            convert: anyNamed('convert'),
          ),
        ).captured;

        final body =
            jsonDecode(captured.single as String) as Map<String, dynamic>;
        expect(body['status'], 'in_progress');
        expect(body['details_url'], 'https://example.com/details');
        expect(body['conclusion'], isNull);
        expect(body['completed_at'], isNull);
      },
    );
  });
}
