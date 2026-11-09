// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/scheduler/process_check_run_result.dart';
import 'package:github/github.dart' hide Branch, CheckRun;
import 'package:github/github.dart' as github show CheckRun;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/request_handling/subscription_tester.dart';

final class _PrCall {
  const _PrCall(this.slug, this.prNumber, this.triggerReason);
  final RepositorySlug slug;
  final int prNumber;
  final String? triggerReason;
}

final class _MgCall {
  const _MgCall(this.slug, this.prNumber, this.mergeGroupSha);
  final RepositorySlug slug;
  final int prNumber;
  final String mergeGroupSha;
}

final class _FakeWantLgtmReconciler implements WantLgtmReconciler {
  final List<_PrCall> prCalls = [];
  final List<_MgCall> mgCalls = [];

  @override
  Future<WantLgtmReconcileResult> reconcilePullRequest(
    RepositorySlug slug,
    int prNumber, {
    PullRequest? pullRequest,
    String? triggerReason,
  }) async {
    prCalls.add(_PrCall(slug, prNumber, triggerReason));
    return const WantLgtmReconcileSkipped(reason: 'fake');
  }

  @override
  Future<github.CheckRun> reconcileMergeGroup({
    required RepositorySlug slug,
    required int prNumber,
    required String mergeGroupSha,
  }) async {
    mgCalls.add(_MgCall(slug, prNumber, mergeGroupSha));
    return WantLgtmCheckWriter.checkRunWithId(999);
  }
}

void main() {
  useTestLoggerPerTest();

  setUpAll(() {
    provideDummy<ProcessCheckRunResult>(const ProcessCheckRunResult.success());
  });

  final slug = RepositorySlug('flutter', 'flutter');
  const prNumber = 123;
  const headSha = 'abc';

  late FakeConfig config;
  late MockGitHub gitHubClient;
  late FakeGithubService githubService;
  late MockCommitService commitService;
  late MockScheduler scheduler;
  late FakeGerritService gerritService;
  late FakeFirestoreService firestore;
  late MockIssuesService issuesService;
  late MockPullRequestsService pullRequestsService;
  late MockPullRequestLabelProcessor pullRequestLabelProcessor;
  late _FakeWantLgtmReconciler fakeReconciler;
  late SubscriptionTester tester;
  late GithubWebhookSubscription webhook;

  setUp(() {
    gitHubClient = MockGitHub();
    githubService = FakeGithubService();
    commitService = MockCommitService();
    scheduler = MockScheduler();
    gerritService = FakeGerritService();
    firestore = FakeFirestoreService();
    issuesService = MockIssuesService();
    pullRequestsService = MockPullRequestsService();
    pullRequestLabelProcessor = MockPullRequestLabelProcessor();
    fakeReconciler = _FakeWantLgtmReconciler();

    config = FakeConfig(
      githubClient: gitHubClient,
      githubService: githubService,
      rollerAccountsValue: const <String>{'dependabot'},
    );
    config.dynamicConfig = DynamicConfig(
      wantLgtm: WantLgtmFlags(
        enabled: true,
        enabledRepos: const <String>['flutter/flutter'],
      ),
    );

    when(gitHubClient.issues).thenReturn(issuesService);
    when(gitHubClient.pullRequests).thenReturn(pullRequestsService);
    when(
      pullRequestsService.listFiles(slug, prNumber),
    ).thenAnswer((_) => const Stream<PullRequestFile>.empty());
    when(
      issuesService.listCommentsByIssue(slug, prNumber),
    ).thenAnswer((_) => const Stream<IssueComment>.empty());
    when(
      issuesService.createComment(any, any, any),
    ).thenAnswer((_) async => IssueComment());
    when(pullRequestLabelProcessor.processLabels()).thenAnswer((_) async {});
    when(
      scheduler.createAwaitingCicdLabelCheckRun(any, any),
    ).thenAnswer((_) async => null);

    when(
      scheduler.processCheckRun(any),
    ).thenAnswer((_) async => const ProcessCheckRunResult.success());
    when(
      scheduler.handleMergeGroupEvent(
        mergeGroupEvent: anyNamed('mergeGroupEvent'),
      ),
    ).thenAnswer((_) async => true);

    tester = SubscriptionTester(request: FakeHttpRequest());
    webhook = GithubWebhookSubscription(
      cache: CacheService.inMemory(),
      config: config,
      scheduler: scheduler,
      gerritService: gerritService,
      commitService: commitService,
      firestore: firestore,
      pullRequestLabelProcessorProvider:
          ({
            required Config config,
            required GithubService githubService,
            required PullRequest pullRequest,
          }) => pullRequestLabelProcessor,
      wantLgtmReconciler: fakeReconciler,
    );
  });

  group('pull_request routing to WANT_LGTM reconciler', () {
    for (final action in const <String>[
      'opened',
      'synchronize',
      'edited',
      'ready_for_review',
      'reopened',
      'review_requested',
      'review_request_removed',
    ]) {
      test('routes action $action to reconciler', () async {
        tester.message = generateGithubWebhookMessage(
          action: action,
          number: prNumber,
          slug: slug,
          headSha: headSha,
        );

        final response = await tester.post(webhook);
        expect(response, same(Response.emptyOk));
        expect(fakeReconciler.prCalls, hasLength(1));
        final call = fakeReconciler.prCalls.single;
        expect(call.slug, slug);
        expect(call.prNumber, prNumber);
        expect(call.triggerReason, action);
      });
    }

    test('routes action closed to reconciler', () async {
      tester.message = generateGithubWebhookMessage(
        action: 'closed',
        number: prNumber,
        slug: slug,
        headSha: headSha,
        merged: false,
      );

      final response = await tester.post(webhook);
      expect(response, same(Response.emptyOk));
      expect(fakeReconciler.prCalls, hasLength(1));
      final call = fakeReconciler.prCalls.single;
      expect(call.slug, slug);
      expect(call.prNumber, prNumber);
      expect(call.triggerReason, 'closed');
    });
  });

  group('pull_request_review routing to WANT_LGTM reconciler', () {
    for (final action in const <String>['submitted', 'dismissed']) {
      test('routes review action $action to reconciler', () async {
        tester.message = _createReviewMessage(
          action: action,
          slug: slug,
          prNumber: prNumber,
        );

        final response = await tester.post(webhook);
        expect(response, same(Response.emptyOk));
        expect(fakeReconciler.prCalls, hasLength(1));
        final call = fakeReconciler.prCalls.single;
        expect(call.slug, slug);
        expect(call.prNumber, prNumber);
        expect(call.triggerReason, 'review_$action');
      });
    }

    test('ignores non-review actions such as commented or edited', () async {
      tester.message = _createReviewMessage(
        action: 'edited',
        slug: slug,
        prNumber: prNumber,
      );

      final response = await tester.post(webhook);
      expect(response, same(Response.emptyOk));
      expect(fakeReconciler.prCalls, isEmpty);
    });

    test('throws InternalServerError on unsupported repository', () async {
      final unsupported = RepositorySlug('flutter', 'unsupported_repo');
      tester.message = _createReviewMessage(
        action: 'submitted',
        slug: unsupported,
        prNumber: prNumber,
      );

      expect(tester.post(webhook), throwsA(isA<InternalServerError>()));
      expect(fakeReconciler.prCalls, isEmpty);
    });
  });

  group('check_run routing with WANT_LGTM check run', () {
    test(
      'rerequested WANT_LGTM triggers reconciler and skips scheduler',
      () async {
        tester.message = _createCheckRunMessage(
          action: 'rerequested',
          checkName: Config.kWantLgtmCheckName,
          slug: slug,
          prNumber: prNumber,
        );

        final response = await tester.post(webhook);
        expect(response, same(Response.emptyOk));
        expect(fakeReconciler.prCalls, hasLength(1));
        final call = fakeReconciler.prCalls.single;
        expect(call.slug, slug);
        expect(call.prNumber, prNumber);
        expect(call.triggerReason, 'check_run_rerequested');
        verifyNever(scheduler.processCheckRun(any));
      },
    );

    test(
      'non-rerequested WANT_LGTM returns emptyOk without calling scheduler',
      () async {
        tester.message = _createCheckRunMessage(
          action: 'completed',
          checkName: Config.kWantLgtmCheckName,
          slug: slug,
          prNumber: prNumber,
        );

        final response = await tester.post(webhook);
        expect(response, same(Response.emptyOk));
        expect(fakeReconciler.prCalls, isEmpty);
        verifyNever(scheduler.processCheckRun(any));
      },
    );

    test('other check runs forward to scheduler', () async {
      tester.message = _createCheckRunMessage(
        action: 'completed',
        checkName: 'Linux build',
        slug: slug,
        prNumber: prNumber,
      );

      final response = await tester.post(webhook);
      expect(response, same(Response.emptyOk));
      expect(fakeReconciler.prCalls, isEmpty);
      verify(scheduler.processCheckRun(any)).called(1);
    });
  });

  group('merge_group routing with WANT_LGTM', () {
    test(
      'checks_requested waives WANT_LGTM on merge group headSha for enrolled repo',
      () async {
        tester.message = generateMergeGroupMessage(
          action: 'checks_requested',
          message: 'Checks requested for merge group',
          repository: 'flutter/flutter',
          headSha: headSha,
          headRef: 'refs/heads/gh-readonly-queue/master/pr-42-sha123',
        );

        final response = await tester.post(webhook);
        expect(response, same(Response.emptyOk));
        verify(
          scheduler.handleMergeGroupEvent(
            mergeGroupEvent: anyNamed('mergeGroupEvent'),
          ),
        ).called(1);
        expect(fakeReconciler.mgCalls, hasLength(1));
        final call = fakeReconciler.mgCalls.single;
        expect(call.slug, slug);
        expect(call.prNumber, 42);
        expect(call.mergeGroupSha, headSha);
      },
    );

    test(
      'checks_requested does not waive WANT_LGTM if repo is not enrolled',
      () async {
        config.dynamicConfig = DynamicConfig(
          wantLgtm: WantLgtmFlags(enabledRepos: const <String>[]),
        );

        tester.message = generateMergeGroupMessage(
          action: 'checks_requested',
          message: 'Checks requested for merge group',
          repository: 'flutter/flutter',
          headSha: headSha,
          headRef: 'refs/heads/gh-readonly-queue/master/pr-42-sha123',
        );

        final response = await tester.post(webhook);
        expect(response, same(Response.emptyOk));
        expect(fakeReconciler.mgCalls, isEmpty);
      },
    );
  });
}

Map<String, dynamic> _repoJson(RepositorySlug slug) => <String, dynamic>{
  'id': 186853002,
  'name': slug.name,
  'owner': <String, dynamic>{
    'id': 1,
    'login': slug.owner,
    'avatar_url': 'https://avatars.example.com/u/1',
    'html_url': 'https://github.com/${slug.owner}',
  },
};

PushMessage _createReviewMessage({
  required String action,
  required RepositorySlug slug,
  required int prNumber,
}) {
  final payload = jsonEncode(<String, dynamic>{
    'action': action,
    'repository': _repoJson(slug),
    'pull_request': <String, dynamic>{
      'id': 279147437,
      'number': prNumber,
      'head': <String, dynamic>{
        'ref': 'changes',
        'sha': 'head_sha',
        'repo': _repoJson(slug),
      },
      'base': <String, dynamic>{
        'ref': 'master',
        'sha': 'base_sha',
        'repo': _repoJson(slug),
      },
    },
    'review': <String, dynamic>{
      'id': 1001,
      'state': 'APPROVED',
      'user': <String, dynamic>{'id': 101, 'login': 'codefu'},
    },
  });
  final msg = pb.GithubWebhookMessage.create()
    ..event = 'pull_request_review'
    ..payload = payload;
  return PushMessage(data: msg.writeToJson());
}

PushMessage _createCheckRunMessage({
  required String action,
  required String checkName,
  required RepositorySlug slug,
  int? prNumber,
}) {
  final payload = jsonEncode(<String, dynamic>{
    'action': action,
    'repository': _repoJson(slug),
    'check_run': <String, dynamic>{
      'id': 2002,
      'name': checkName,
      'head_sha': 'head_sha',
      if (prNumber != null)
        'pull_requests': [
          <String, dynamic>{'number': prNumber},
        ],
    },
  });
  final msg = pb.GithubWebhookMessage.create()
    ..event = 'check_run'
    ..payload = payload;
  return PushMessage(data: msg.writeToJson());
}
