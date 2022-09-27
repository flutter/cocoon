// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/github/webhook_subscription.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import 'package:github/github.dart' hide Branch;
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/datastore/fake_datastore.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/service/fake_buildbucket.dart';
import '../../src/service/fake_github_service.dart';
import '../../src/service/fake_scheduler.dart';
import '../../src/utilities/mocks.dart';
import '../../src/utilities/webhook_generators.dart';

void main() {
  late GithubWebhookSubscription webhook;
  late FakeBuildBucketClient fakeBuildBucketClient;
  late FakeConfig config;
  late FakeDatastoreDB db;
  late FakeGithubService githubService;
  late FakeHttpRequest request;
  late FakeScheduler scheduler;
  late MockGitHub gitHubClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late MockGithubChecksService mockGithubChecksService;
  late MockIssuesService issuesService;
  late MockPullRequestsService pullRequestsService;
  late SubscriptionTester tester;

  setUp(() {
    request = FakeHttpRequest();
    db = FakeDatastoreDB();
    gitHubClient = MockGitHub();
    githubService = FakeGithubService();
    final MockTabledataResource tabledataResource = MockTabledataResource();
    when(tabledataResource.insertAll(any, any, any, any)).thenAnswer((_) async => TableDataInsertAllResponse());
    config = FakeConfig(
      dbValue: db,
      githubClient: gitHubClient,
      githubService: githubService,
      githubOAuthTokenValue: 'githubOAuthKey',
      missingTestsPullRequestMessageValue: 'missingTestPullRequestMessage',
      releaseBranchPullRequestMessageValue: 'releaseBranchPullRequestMessage',
      rollerAccountsValue: const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot',
      },
      tabledataResource: tabledataResource,
      wrongHeadBranchPullRequestMessageValue: 'wrongHeadBranchPullRequestMessage',
      wrongBaseBranchPullRequestMessageValue: '{{target_branch}} -> {{default_branch}}',
    );
    issuesService = MockIssuesService();
    when(issuesService.addLabelsToIssue(any, any, any)).thenAnswer((_) async => <IssueLabel>[]);
    when(issuesService.createComment(any, any, any)).thenAnswer((_) async => IssueComment());
    when(issuesService.listCommentsByIssue(any, any))
        .thenAnswer((_) => Stream<IssueComment>.fromIterable(<IssueComment>[IssueComment()]));
    pullRequestsService = MockPullRequestsService();
    when(pullRequestsService.listFiles(Config.flutterSlug, any))
        .thenAnswer((_) => const Stream<PullRequestFile>.empty());
    when(pullRequestsService.edit(any, any, title: anyNamed('title'), state: anyNamed('state'), base: anyNamed('base')))
        .thenAnswer((_) async => PullRequest());
    fakeBuildBucketClient = FakeBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    scheduler = FakeScheduler(
      config: config,
      buildbucket: fakeBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
    );
    tester = SubscriptionTester(request: request);

    mockGithubChecksService = MockGithubChecksService();
    when(gitHubClient.issues).thenReturn(issuesService);
    when(gitHubClient.pullRequests).thenReturn(pullRequestsService);
    when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output'))).thenAnswer((_) async {
      return CheckRun.fromJson(const <String, dynamic>{
        'id': 1,
        'started_at': '2020-05-10T02:49:31Z',
        'check_suite': <String, dynamic>{'id': 2}
      });
    });

    webhook = GithubWebhookSubscription(
      config: config,
      cache: CacheService(inMemory: true),
      datastoreProvider: (_) => DatastoreService(config.db, 5),
      githubChecksService: mockGithubChecksService,
      scheduler: scheduler,
    );
  });

  group('github webhook check_run event', () {
    test('processes check run event', () async {
      tester.message = generateCheckRunEvent();

      await tester.post(webhook);
    });

    test('processes completed check run event', () async {
      tester.message = generateCheckRunEvent(
        action: 'completed',
        numberOfPullRequests: 0,
      );

      await tester.post(webhook);
    });
  });
}
