// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';

import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late MockGithubChecksUtil mockGithubChecksUtil;
  late MockLuciBuildService mockLuciBuildService;
  late GithubChecksService githubChecksService;
  late github.CheckRun checkRun;
  late RepositorySlug slug;

  setUp(() {
    final mockGithubService = MockGithubService();
    mockLuciBuildService = MockLuciBuildService();
    mockGithubChecksUtil = MockGithubChecksUtil();
    final config = FakeConfig(
      githubService: mockGithubService,
      rollerAccountsValue: {'engine-flutter-autoroll'},
    );
    githubChecksService = GithubChecksService(
      config,
      githubChecksUtil: mockGithubChecksUtil,
    );
    slug = RepositorySlug('flutter', 'cocoon');
    checkRun = github.CheckRun.fromJson(
      jsonDecode(
            '{"name": "Linux Coverage", "id": 123, "external_id": "678", "status": "completed", "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 456}}',
          )
          as Map<String, dynamic>,
    );
    final checkRuns = <String, github.CheckRun>{'Cocoon': checkRun};
    // ignore: discarded_futures
    when(mockGithubChecksUtil.allCheckRuns(any, any)).thenAnswer((_) async {
      return checkRuns;
    });
  });

  group('updateCheckStatus', () {
    test('Userdata contain check_run_id', () async {
      when(
        mockGithubChecksUtil.getCheckRun(any, any, any),
      ).thenAnswer((_) async => checkRun);
      when(
        mockLuciBuildService.getBuildById(
          _fakeBuild.id,
          buildMask: anyNamed('buildMask'),
        ),
      ).thenAnswer(
        (_) async => Build(
          id: _fakeBuild.id,
          builder: _fakeBuild.builder,
          summaryMarkdown: 'test summary',
        ),
      );
      await githubChecksService.updateCheckStatus(
        build: _fakeBuild,
        checkRunId: 123,
        luciBuildService: mockLuciBuildService,
        slug: slug,
      );
      final checkRunCaptured =
          await verify(
                mockGithubChecksUtil.updateCheckRun(
                  any,
                  any,
                  captureAny,
                  status: anyNamed('status'),
                  conclusion: anyNamed('conclusion'),
                  detailsUrl: anyNamed('detailsUrl'),
                  output: anyNamed('output'),
                ),
              ).captured.first
              as github.CheckRun;
      expect(checkRunCaptured.id, checkRun.id);
      expect(checkRunCaptured.name, checkRun.name);
    });
    test('Should rerun a failed task for a roller account', () async {
      when(
        mockGithubChecksUtil.getCheckRun(any, any, any),
      ).thenAnswer((_) async => checkRun);
      when(
        mockLuciBuildService.reschedulePresubmitBuild(
          builderName: 'Linux Coverage',
          build: _fakeBuild,
          userData: PresubmitUserData(
            repoOwner: 'flutter',
            repoName: 'cocoon',
            checkRunId: checkRun.id!,
            commitBranch: 'master',
            commitSha: 'abc123',
          ),
          nextAttempt: 1,
        ),
      ).thenAnswer(
        (_) async => Build(id: _fakeBuild.id, builder: _fakeBuild.builder),
      );
      expect(checkRun.status, github.CheckRunStatus.completed);
      await githubChecksService.updateCheckStatus(
        build: _fakeBuild,
        checkRunId: 1,
        luciBuildService: mockLuciBuildService,
        slug: slug,
        rescheduled: true,
      );
      final captured =
          verify(
            mockGithubChecksUtil.updateCheckRun(
              any,
              any,
              captureAny,
              status: captureAnyNamed('status'),
              conclusion: captureAnyNamed('conclusion'),
              detailsUrl: anyNamed('detailsUrl'),
              output: anyNamed('output'),
            ),
          ).captured;
      expect(captured.length, 3);
      expect(captured[1], github.CheckRunStatus.queued);
      expect(captured[2], isNull);
    });
    test('Should not rerun a failed task for a non roller account', () async {
      when(
        mockGithubChecksUtil.getCheckRun(any, any, any),
      ).thenAnswer((_) async => checkRun);
      when(
        mockLuciBuildService.reschedulePresubmitBuild(
          builderName: 'Linux Coverage',
          build: _fakeBuild,
          userData: PresubmitUserData(
            repoOwner: 'flutter',
            repoName: 'cocoon',
            checkRunId: checkRun.id!,
            commitBranch: 'master',
            commitSha: 'abc123',
          ),
          nextAttempt: 1,
        ),
      ).thenAnswer(
        (_) async => Build(id: _fakeBuild.id, builder: _fakeBuild.builder),
      );
      when(
        mockLuciBuildService.getBuildById(
          _fakeBuild.id,
          buildMask: anyNamed('buildMask'),
        ),
      ).thenAnswer(
        (_) async => Build(
          id: _fakeBuild.id,
          builder: _fakeBuild.builder,
          summaryMarkdown: 'test summary',
        ),
      );
      await githubChecksService.updateCheckStatus(
        build: _fakeBuild,
        checkRunId: 1,
        luciBuildService: mockLuciBuildService,
        slug: slug,
      );
      final captured =
          verify(
            mockGithubChecksUtil.updateCheckRun(
              any,
              any,
              any,
              status: captureAnyNamed('status'),
              conclusion: captureAnyNamed('conclusion'),
              detailsUrl: anyNamed('detailsUrl'),
              output: captureAnyNamed('output'),
            ),
          ).captured;
      expect(captured.length, 3);
      expect(captured[0], github.CheckRunStatus.completed);
      expect(captured[1], github.CheckRunConclusion.failure);
    });
  });

  group('getGithubSummary', () {
    test('nonempty summaryMarkdown', () async {
      const summaryMarkdown = 'test';
      const expectedSummary = '$kGithubSummary$summaryMarkdown';
      expect(
        githubChecksService.getGithubSummary(summaryMarkdown),
        expectedSummary,
      );
    });

    test('empty summaryMarkdown', () async {
      const expectedSummary = '${kGithubSummary}Empty summaryMarkdown';
      expect(githubChecksService.getGithubSummary(null), expectedSummary);
    });

    test('really large summaryMarkdown', () async {
      var summaryMarkdown = '';
      for (var i = 0; i < 20000; i++) {
        summaryMarkdown += 'test ';
      }
      expect(
        githubChecksService.getGithubSummary(summaryMarkdown),
        startsWith('$kGithubSummary[TRUNCATED...]'),
      );
      expect(
        githubChecksService.getGithubSummary(summaryMarkdown).length,
        lessThan(65535),
      );
    });
  });
}

final Build _fakeBuild = Build(
  id: Int64(8905920700440101120),
  builder: BuilderID(
    project: 'flutter',
    bucket: 'luci.flutter.prod',
    builder: 'Linux Coverage',
  ),
  number: 1698,
  createdBy: 'user:someuser@flutter.dev',
  viewUrl: 'https://ci.chromium.org/b/8905920700440101120',
  createTime: Timestamp(seconds: Int64(1565049186), nanos: 247524),
  updateTime: Timestamp(seconds: Int64(1565049194), nanos: 391321),
  status: Status.FAILURE,
  input: Build_Input(experimental: true),
  tags: [
    StringPair(
      key: 'build_address',
      value: 'luci.flutter.prod/Linux Coverage/1698',
    ),
    StringPair(key: 'builder', value: 'Linux Coverage'),
    StringPair(key: 'buildset', value: 'pr/git/37647'),
  ],
);
