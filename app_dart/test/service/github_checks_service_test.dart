// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as push_message;
import 'package:cocoon_service/src/service/github_checks_service.dart';

import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../model/github/checks_test_data.dart';
import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/utilities/mocks.dart' as mocks;
import '../src/utilities/mocks.dart';

void main() {
  FakeConfig config;
  mocks.MockLuciBuildService mockLuciBuildService;
  MockGitHub mockGitHub;
  MockGithubChecksUtil mockGithubChecksUtil;
  GithubChecksService githubChecksService;
  github.CheckRun checkRun;
  RepositorySlug slug;

  const Build linuxBuild = Build(
    id: 998,
    builderId: BuilderId(
      project: 'flutter',
      bucket: 'prod',
      builder: 'Linux',
    ),
    status: Status.failure,
  );

  setUp(() {
    config = FakeConfig();
    mockGithubChecksUtil = MockGithubChecksUtil();
    githubChecksService = GithubChecksService(
      config,
      githubChecksUtil: mockGithubChecksUtil,
    );
    githubChecksService.setLogger(FakeLogging());
    slug = RepositorySlug('flutter', 'cocoon');
    mockLuciBuildService = mocks.MockLuciBuildService();
    mockGitHub = MockGitHub();
    config.githubClient = mockGitHub;
    checkRun = github.CheckRun.fromJson(
      jsonDecode(
              '{"name": "Linux", "id": 123, "external_id": "678", "status": "completed", "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 456}}')
          as Map<String, dynamic>,
    );
    final Map<String, github.CheckRun> checkRuns = <String, github.CheckRun>{'Linux': checkRun};
    when(mockGithubChecksUtil.allCheckRuns(any, any)).thenAnswer((_) async {
      return checkRuns;
    });
  });

  group('handleCheckSuiteEvent', () {
    test('requested triggers all builds', () async {
      final RepositorySlug slug = RepositorySlug('abc', 'cocoon');
      final CheckSuiteEvent checkSuiteEvent =
          CheckSuiteEvent.fromJson(jsonDecode(checkSuiteString) as Map<String, dynamic>);
      await githubChecksService.handleCheckSuite(checkSuiteEvent, mockLuciBuildService);
      expect(
        verify(mockLuciBuildService.scheduleTryBuilds(
          commitSha: captureAnyNamed('commitSha'),
          prNumber: captureAnyNamed('prNumber'),
          slug: captureAnyNamed('slug'),
          checkSuiteEvent: anyNamed('checkSuiteEvent'),
        )).captured,
        <dynamic>['dabc07b74c555c9952f7b63e139f2bb83b75250f', 758, slug],
      );
    });
    test('re-requested triggers failed builds only', () async {
      when(mockLuciBuildService.failedBuilds(any, any, any)).thenAnswer((_) async {
        return <Build>[linuxBuild];
      });
      final CheckSuiteEvent checkSuiteEvent =
          CheckSuiteEvent.fromJson(jsonDecode(checkSuiteTemplate('rerequested')) as Map<String, dynamic>);
      await githubChecksService.handleCheckSuite(
        checkSuiteEvent,
        mockLuciBuildService,
      );
      expect(
          verify(mockLuciBuildService.rescheduleTryBuildUsingCheckSuiteEvent(captureAny, captureAny)).captured,
          <dynamic>[
            checkSuiteEvent,
            checkRun,
          ]);
    });
  });
  group('handleCheckRunEvent', () {
    test('rerequested triggers triggers a luci build', () async {
      final CheckRunEvent checkRunEvent = CheckRunEvent.fromJson(
        jsonDecode(checkRunString) as Map<String, dynamic>,
      );
      await githubChecksService.handleCheckRun(
        checkRunEvent,
        mockLuciBuildService,
      );
      expect(
          verify(mockLuciBuildService.rescheduleUsingCheckRunEvent(
            captureAny,
          )).captured,
          <dynamic>[checkRunEvent]);
    });
  });
  group('updateCheckStatus', () {
    test('Userdata is empty', () async {
      final push_message.BuildPushMessage buildMessage =
          push_message.BuildPushMessage.fromJson(jsonDecode(buildPushMessageJsonTemplate('')) as Map<String, dynamic>);
      final bool success = await githubChecksService.updateCheckStatus(buildMessage, mockLuciBuildService, slug);
      expect(success, isFalse);
    });
    test('Userdata does not contain check_run_id', () async {
      final push_message.BuildPushMessage buildMessage = push_message.BuildPushMessage.fromJson(
          jsonDecode(buildPushMessageJsonTemplate('{\\"retries\\": 1}')) as Map<String, dynamic>);
      final bool success = await githubChecksService.updateCheckStatus(buildMessage, mockLuciBuildService, slug);
      expect(success, isFalse);
    });
    test('Userdata contain check_run_id', () async {
      when(mockGithubChecksUtil.getCheckRun(any, any, any)).thenAnswer((_) async => checkRun);
      final push_message.BuildPushMessage buildPushMessage =
          push_message.BuildPushMessage.fromJson(jsonDecode(buildPushMessageJsonTemplate('{\\"check_run_id\\": 1,'
              '\\"repo_owner\\": \\"flutter\\",'
              '\\"repo_name\\": \\"cocoon\\"}')) as Map<String, dynamic>);
      await githubChecksService.updateCheckStatus(buildPushMessage, mockLuciBuildService, slug);
      expect(
          verify(mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            captureAny,
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            detailsUrl: anyNamed('detailsUrl'),
            output: anyNamed('output'),
          )).captured,
          <github.CheckRun>[checkRun]);
    });
  });
}

String buildPushMessageJsonTemplate(String jsonUserData) => '''{
  "build": {
    "bucket": "luci.flutter.prod",
    "canary": false,
    "canary_preference": "PROD",
    "created_by": "user:dnfield@google.com",
    "created_ts": "1565049186247524",
    "experimental": true,
    "id": "8905920700440101120",
    "parameters_json": "{\\"builder_name\\": \\"Linux Coverage\\", \\"properties\\": {\\"git_ref\\": \\"refs/pull/37647/head\\", \\"git_url\\": \\"https://github.com/flutter/flutter\\"}}",
    "project": "flutter",
    "result_details_json": "{\\"properties\\": {}, \\"swarming\\": {\\"bot_dimensions\\": {\\"caches\\": [\\"flutter_openjdk_install\\", \\"git\\", \\"goma_v2\\", \\"vpython\\"], \\"cores\\": [\\"8\\"], \\"cpu\\": [\\"x86\\", \\"x86-64\\", \\"x86-64-Broadwell_GCE\\", \\"x86-64-avx2\\"], \\"gce\\": [\\"1\\"], \\"gpu\\": [\\"none\\"], \\"id\\": [\\"luci-flutter-prod-xenial-2-bnrz\\"], \\"image\\": [\\"chrome-xenial-19052201-9cb74617499\\"], \\"inside_docker\\": [\\"0\\"], \\"kvm\\": [\\"1\\"], \\"locale\\": [\\"en_US.UTF-8\\"], \\"machine_type\\": [\\"n1-standard-8\\"], \\"os\\": [\\"Linux\\", \\"Ubuntu\\", \\"Ubuntu-16.04\\"], \\"pool\\": [\\"luci.flutter.prod\\"], \\"python\\": [\\"2.7.12\\"], \\"server_version\\": [\\"4382-5929880\\"], \\"ssd\\": [\\"0\\"], \\"zone\\": [\\"us\\", \\"us-central\\", \\"us-central1\\", \\"us-central1-c\\"]}}}",
    "service_account": "flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com",
    "started_ts": "1565049193786080",
    "status": "STARTED",
    "result": "FAILURE",
    "status_changed_ts": "1565049194386647",
    "tags": [
      "build_address:luci.flutter.prod/Linux Coverage/1698",
      "builder:Linux Coverage",
      "buildset:pr/git/37647",
      "buildset:sha/git/0d78fc94f890a64af140ce0a2671ac5fc636f59b",
      "swarming_hostname:chromium-swarm.appspot.com",
      "swarming_tag:log_location:logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket.appspot.com/8905920700440101120/+/annotations",
      "swarming_tag:luci_project:flutter",
      "swarming_tag:os:Linux",
      "swarming_tag:recipe_name:flutter/flutter",
      "swarming_tag:recipe_package:infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
      "swarming_task_id:467d04f2f022d510"
    ],
    "updated_ts": "1565049194391321",
    "url": "https://ci.chromium.org/b/8905920700440101120",
    "utcnow_ts": "1565049194653640"
  },
  "hostname": "cr-buildbucket.appspot.com",
  "user_data": "$jsonUserData"
}''';
