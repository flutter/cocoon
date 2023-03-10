// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/model/merge_comment_message.dart';
import 'package:auto_submit/service/merge_update_service.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/mocks.mocks.dart';

import 'merge_update_service_test_data.dart';

void main() {
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;
  late MergeUpdateService mergeUpdateService;
  late RepositorySlug slug;
  late GitReference gitReferenceMock;

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(
      githubService: githubService,
      githubGraphQLClient: githubGraphQLClient,
    );

    mergeUpdateService = MergeUpdateService(config);
    slug = RepositorySlug(
      'flutter',
      'cocoon',
    );

    gitReferenceMock = GitReference.fromJson(json.decode(gitReference) as Map<String, dynamic>);
    githubService.gitReferenceMock = gitReferenceMock;
  });

  test('Closed pullRequest is ignored.', () async {
    final PullRequest pullRequest = PullRequest(state: 'closed');
    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      authorAssociation: 'MEMBER',
      id: 111,
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = null;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('Null IssueComment is not processed.', () async {
    final PullRequest pullRequest = PullRequest(
      state: 'open',
      mergeable: true,
    );
    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      authorAssociation: 'MEMBER',
      id: 111,
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = null;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    expect(
      githubService.getCommentInvocations,
      1,
    );
    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('IssueComment not found with Exception is handled.', () async {
    final PullRequest pullRequest = PullRequest(state: 'open');
    githubService.gitHubError = NotFound(MockGitHub(), 'Not Found.');
    githubService.getCommentThrowsException = true;

    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      authorAssociation: 'MEMBER',
      id: 111,
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = null;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    expect(
      githubService.getCommentInvocations,
      1,
    );
    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('Null IssueComment body is not processed.', () async {
    final PullRequest pullRequest = PullRequest(state: 'open');

    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      authorAssociation: 'MEMBER',
      id: 111,
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = issueComment;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('Issue body text does not match merge request text.', () async {
    final PullRequest pullRequest = PullRequest(state: 'open');

    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      authorAssociation: 'MEMBER',
      id: 111,
      body: 'Hello World.',
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = issueComment;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('Null authorAssociation is handled correctly.', () async {
    final PullRequest pullRequest = PullRequest(state: 'open');

    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      id: 111,
      body: '@autosubmit:merge',
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = issueComment;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    expect(
      githubService.getCommentInvocations,
      1,
    );
    expect(
      githubService.issueComment!.body!.contains('You must be a MEMBER or OWNER author to request a merge update'),
      isTrue,
    );
    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('Non Member/Owner authorAssociation is not processed.', () async {
    final PullRequest pullRequest = PullRequest(
      state: 'open',
      mergeable: true,
    );

    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      //TODO change back to contributor after testing.
      authorAssociation: 'ASSOCIATE',
      id: 111,
      body: '@autosubmit:merge',
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = issueComment;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    expect(
      githubService.getCommentInvocations,
      1,
    );
    expect(
      githubService.issueComment!.body!.contains('You must be a MEMBER or OWNER author to request a merge update'),
      isTrue,
    );
    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('Update branch is successful.', () async {
    final PullRequest pullRequest = PullRequest(state: 'open', number: 10);

    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      authorAssociation: 'OWNER',
      id: 111,
      body: '@autosubmit:merge',
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = issueComment;
    githubService.pullRequestMock = pullRequest;
    githubService.autoMergeResult = true;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    expect(
      githubService.getCommentInvocations,
      1,
    );
    expect(
      githubService.issueComment!.body!.contains('Successfully updated'),
      isTrue,
    );
    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });

  test('Update branch is unsuccessful.', () async {
    final PullRequest pullRequest = PullRequest(state: 'open', number: 10);
    githubService.updateBranchValue = false;
    githubService.useRealComment = true;
    final Repository repository = Repository(fullName: slug.fullName);
    final IssueComment issueComment = IssueComment(
      authorAssociation: 'OWNER',
      id: 111,
      body: '@autosubmit:merge',
    );
    final Issue issue = Issue(number: 1);

    githubService.issueCommentMock = issueComment;
    githubService.pullRequestMock = pullRequest;

    final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
      issue: issue,
      comment: issueComment,
      repository: repository,
    );

    final FakePubSub pubSub = FakePubSub();
    await mergeUpdateService.processMessage(
      mergeCommentMessage,
      '1',
      FakePubSub(),
    );

    expect(
      githubService.getCommentInvocations,
      1,
    );
    expect(
      githubService.issueComment!.body!.contains('Unable to update'),
      isTrue,
    );
    // Validate some other issue did not take place.
    expect(
      pubSub.messagesQueue.length,
      0,
    );
  });
}
