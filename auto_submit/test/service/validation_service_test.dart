// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' as autosubmit hide PullRequest;
import 'package:auto_submit/service/validation_service.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart' hide Request, Response;
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/service/fake_github_service.dart';
import '../utilities/utils.dart';
import '../utilities/mocks.dart';

void main() {
  late ValidationService validationService;
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;
  late RepositorySlug slug;

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
    validationService = ValidationService(config);
    slug = RepositorySlug('flutter', 'cocoon');
  });

  test('removes label and post comment when no approval', () async {
    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    githubService.checkRunsData = checkRunsMock;
    githubService.createCommentData = createCommentMock;
    githubService.commitData = commitMock;
    githubService.compareTwoCommitsData = shouldRebaseMock;
    final FakePubSub pubsub = FakePubSub();
    final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
    pubsub.publish('auto-submit-queue-sub', pullRequest);
    autosubmit.QueryResult queryResult = createQueryResult(flutterRequest);

    await validationService.processPullRequest(config, queryResult, pullRequest, 'test', pubsub);

    expect(githubService.issueComment, isNotNull);
    expect(githubService.labelRemoved, true);
    assert(pubsub.messagesQueue.isEmpty);
  });

  test('land ToT revert ignoring validation failure', () async {
    githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult();
    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      // Assumes no approval exists.
      reviews: <PullRequestReviewHelper>[],
    );
    githubService.checkRunsData = checkRunsMock;
    githubService.createCommentData = createCommentMock;
    githubService.commitData = commitMock;
    // Assumes ToT commit revert.
    githubService.compareTwoCommitsData = compareToTCommitsMock;
    final FakePubSub pubsub = FakePubSub();
    final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
    pubsub.publish('auto-submit-queue-sub', pullRequest);
    autosubmit.QueryResult queryResult = createQueryResult(flutterRequest);

    await validationService.processPullRequest(config, queryResult, pullRequest, 'test', pubsub);

    expect(githubService.issueComment, isNull);
    expect(githubService.labelRemoved, false);
    assert(pubsub.messagesQueue.isEmpty);
  });
}
