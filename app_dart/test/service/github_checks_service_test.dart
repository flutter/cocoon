// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:fixnum/fixnum.dart';

import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../model/github/checks_test_data.dart';
import '../src/datastore/fake_config.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  FakeConfig config;
  late FakeScheduler scheduler;
  MockGithubService mockGithubService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late MockLuciBuildService mockLuciBuildService;
  late GithubChecksService githubChecksService;
  late github.CheckRun checkRun;
  late RepositorySlug slug;

  setUp(() {
    mockGithubService = MockGithubService();
    mockLuciBuildService = MockLuciBuildService();
    when(mockGithubService.listFiles(any)).thenAnswer((_) async => <String>[]);
    mockGithubChecksUtil = MockGithubChecksUtil();
    config = FakeConfig(githubService: mockGithubService, rollerAccountsValue: {'engine-flutter-autoroll'});
    githubChecksService = GithubChecksService(
      config,
      githubChecksUtil: mockGithubChecksUtil,
    );
    slug = RepositorySlug('flutter', 'cocoon');
    scheduler = FakeScheduler(
      config: config,
      luciBuildService: mockLuciBuildService,
      githubChecksUtil: mockGithubChecksUtil,
      ciYaml: exampleConfig,
    );
    checkRun = github.CheckRun.fromJson(
      jsonDecode(
        '{"name": "Linux Coverage", "id": 123, "external_id": "678", "status": "completed", "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 456}}',
      ) as Map<String, dynamic>,
    );
    final Map<String, github.CheckRun> checkRuns = <String, github.CheckRun>{'Cocoon': checkRun};
    when(mockGithubChecksUtil.allCheckRuns(any, any)).thenAnswer((_) async {
      return checkRuns;
    });
  });

  group('updateCheckStatus', () {
    test('Userdata is empty', () async {
      final bool success = await githubChecksService.updateCheckStatus(
        build: _fakeBuild,
        userDataMap: {},
        luciBuildService: mockLuciBuildService,
        slug: slug,
      );
      expect(success, isFalse);
    });
    test('Userdata does not contain check_run_id', () async {
      final bool success = await githubChecksService.updateCheckStatus(
        build: _fakeBuild,
        userDataMap: {'repo_name': 'flutter/flutter'},
        luciBuildService: mockLuciBuildService,
        slug: slug,
      );
      expect(success, isFalse);
    });
    test('Userdata contain check_run_id', () async {
      when(mockGithubChecksUtil.getCheckRun(any, any, any)).thenAnswer((_) async => checkRun);
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
      final userData = {
        'check_run_id': 123,
        'repo_owner': 'flutter',
        'repo_name': 'cocoon',
      };
      await githubChecksService.updateCheckStatus(
        build: _fakeBuild,
        userDataMap: userData,
        luciBuildService: mockLuciBuildService,
        slug: slug,
      );
      final github.CheckRun checkRunCaptured = await verify(
        mockGithubChecksUtil.updateCheckRun(
          any,
          any,
          captureAny,
          status: anyNamed('status'),
          conclusion: anyNamed('conclusion'),
          detailsUrl: anyNamed('detailsUrl'),
          output: anyNamed('output'),
        ),
      ).captured.first;
      expect(checkRunCaptured.id, checkRun.id);
      expect(checkRunCaptured.name, checkRun.name);
    });
    test('Should rerun a failed task for a roller account', () async {
      when(mockGithubChecksUtil.getCheckRun(any, any, any)).thenAnswer((_) async => checkRun);
      final Map<String, dynamic> userData = {
        'check_run_id': 1,
        'repo_owner': 'flutter',
        'repo_name': 'cocoon',
        'user_login': 'engine-flutter-autoroll',
      };
      when(
        mockLuciBuildService.rescheduleBuild(
          builderName: 'Linux Coverage',
          build: _fakeBuild,
          userDataMap: userData,
          rescheduleAttempt: 1,
        ),
      ).thenAnswer(
        (_) async => Build(
          id: _fakeBuild.id,
          builder: _fakeBuild.builder,
        ),
      );
      expect(checkRun.status, github.CheckRunStatus.completed);
      await githubChecksService.updateCheckStatus(
        build: _fakeBuild,
        userDataMap: userData,
        luciBuildService: mockLuciBuildService,
        slug: slug,
        rescheduled: true,
      );
      final List<dynamic> captured = verify(
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
      when(mockGithubChecksUtil.getCheckRun(any, any, any)).thenAnswer((_) async => checkRun);
      final Map<String, dynamic> userData = {
        'check_run_id': 1,
        'repo_owner': 'flutter',
        'repo_name': 'cocoon',
        'user_login': 'test-account',
      };
      when(
        mockLuciBuildService.rescheduleBuild(
          builderName: 'Linux Coverage',
          build: _fakeBuild,
          userDataMap: userData,
          rescheduleAttempt: 1,
        ),
      ).thenAnswer(
        (_) async => Build(
          id: _fakeBuild.id,
          builder: _fakeBuild.builder,
        ),
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
        userDataMap: userData,
        luciBuildService: mockLuciBuildService,
        slug: slug,
      );
      final List<dynamic> captured = verify(
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
      const String summaryMarkdown = 'test';
      const String expectedSummary = '$kGithubSummary$summaryMarkdown';
      expect(githubChecksService.getGithubSummary(summaryMarkdown), expectedSummary);
    });

    test('empty summaryMarkdown', () async {
      const String expectedSummary = '${kGithubSummary}Empty summaryMarkdown';
      expect(githubChecksService.getGithubSummary(null), expectedSummary);
    });

    test('really large summaryMarkdown', () async {
      String summaryMarkdown = '';
      for (int i = 0; i < 20000; i++) {
        summaryMarkdown += 'test ';
      }
      expect(githubChecksService.getGithubSummary(summaryMarkdown), startsWith('$kGithubSummary[TRUNCATED...]'));
      expect(githubChecksService.getGithubSummary(summaryMarkdown).length, lessThan(65535));
    });
  });
}

final Build _fakeBuild = Build(
  id: Int64(8905920700440101120),
  builder: BuilderID(project: 'flutter', bucket: 'luci.flutter.prod', builder: 'Linux Coverage'),
  number: 1698,
  createdBy: 'user:someuser@flutter.dev',
  viewUrl: 'https://ci.chromium.org/b/8905920700440101120',
  createTime: Timestamp(seconds: Int64(1565049186), nanos: 247524),
  updateTime: Timestamp(seconds: Int64(1565049194), nanos: 391321),
  status: Status.FAILURE,
  input: Build_Input(experimental: true),
  tags: [
    StringPair(key: 'build_address', value: 'luci.flutter.prod/Linux Coverage/1698'),
    StringPair(key: 'builder', value: 'Linux Coverage'),
    StringPair(key: 'buildset', value: 'pr/git/37647'),
  ],
);
