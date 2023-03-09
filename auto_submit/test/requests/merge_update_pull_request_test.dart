// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/model/merge_comment_message.dart';
import 'package:auto_submit/requests/merge_update_pull_request.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../service/merge_update_service_test_data.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/mocks.dart';

void main() {
  late MergeUpdatePullRequest pullRequestMergeUpdate;
  late FakeConfig config;
  late FakeGraphQLClient githubGraphQLClient;
  late FakeGithubService githubService;
  late FakeCronAuthProvider auth;
  final MockGitHub gitHub = MockGitHub();
  late FakePubSub pubsub;
  late GitReference gitReferenceMock;

  setUp(() {
    // TODO need to setup a github reference for the fake github service.
    githubGraphQLClient = FakeGraphQLClient();
    auth = FakeCronAuthProvider();
    pubsub = FakePubSub();
    githubService = FakeGithubService();
    config = FakeConfig(
      githubService: githubService,
      githubGraphQLClient: githubGraphQLClient,
      githubClient: gitHub,
    );
  });

  group('CheckPullRequestUpdates()', () {
    test('Multiple identical messages are processed once', () async {
      // Need to add a pullrequest to the pullRequestMock in the FakeGithubService.
      final RepositorySlug slug = RepositorySlug(
        'ricardoamador',
        'flutter_test',
      );
      final PullRequest pullRequest = PullRequest(
        state: 'open',
        mergeable: true,
      );

      final MergeCommentMessage mergeCommentMessage = generateMergeCommentMessage(
        slug: slug,
        addPullRequest: true,
      );

      final IssueComment issueComment = mergeCommentMessage.comment!;
      githubService.issueCommentMock = issueComment;

      gitReferenceMock = GitReference.fromJson(json.decode(gitReference) as Map<String, dynamic>);
      githubService.gitReferenceMock = gitReferenceMock;
      githubService.useRealComment = true;
      githubService.pullRequestMock = pullRequest;

      for (int i = 0; i < 2; i++) {
        unawaited(pubsub.publish(
          'auto-submit-comment-sub',
          mergeCommentMessage,
        ));
      }

      pullRequestMergeUpdate = MergeUpdatePullRequest(
        config: config,
        cronAuthProvider: auth,
        pubsub: pubsub,
      );

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[10] = slug;

      await pullRequestMergeUpdate.get();

      // Verify that processed what we think we processed.
      githubService.verifyBranchUpdates(expectedMergeRequestMap);

      expect(
        0,
        pubsub.messagesQueue.length,
      );
    });

    test('Comments on a closed PR are not processed.', () async {
      // Need to add a pullrequest to the pullRequestMock in the FakeGithubService.
      final RepositorySlug slug = RepositorySlug(
        'ricardoamador',
        'flutter_test',
      );
      final PullRequest pullRequest = PullRequest(
        state: 'closed',
      );

      final MergeCommentMessage mergeCommentMessage = generateMergeCommentMessage(
        slug: slug,
        addPullRequest: true,
      );

      final IssueComment issueComment = mergeCommentMessage.comment!;
      githubService.issueCommentMock = issueComment;

      gitReferenceMock = GitReference.fromJson(json.decode(gitReference) as Map<String, dynamic>);
      githubService.gitReferenceMock = gitReferenceMock;
      githubService.useRealComment = true;
      githubService.pullRequestMock = pullRequest;

      for (int i = 0; i < 2; i++) {
        unawaited(pubsub.publish(
          'auto-submit-comment-sub',
          mergeCommentMessage,
        ));
      }

      pullRequestMergeUpdate = MergeUpdatePullRequest(
        config: config,
        cronAuthProvider: auth,
        pubsub: pubsub,
      );

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};

      await pullRequestMergeUpdate.get();

      // Verify that processed what we think we processed.
      githubService.verifyBranchUpdates(expectedMergeRequestMap);

      expect(
        0,
        pubsub.messagesQueue.length,
      );
    });

    test('Edited comment is not processed.', () async {
      // Need to add a pullrequest to the pullRequestMock in the FakeGithubService.
      final RepositorySlug slug = RepositorySlug(
        'ricardoamador',
        'flutter_test',
      );
      final PullRequest pullRequest = PullRequest(
        state: 'open',
        mergeable: true,
      );

      final MergeCommentMessage mergeCommentMessage = generateMergeCommentMessage(
        slug: slug,
        addPullRequest: true,
        commentBody: 'Do not process',
      );

      final IssueComment issueComment = mergeCommentMessage.comment!;
      githubService.issueCommentMock = issueComment;

      gitReferenceMock = GitReference.fromJson(json.decode(gitReference) as Map<String, dynamic>);
      githubService.gitReferenceMock = gitReferenceMock;
      githubService.useRealComment = true;
      githubService.pullRequestMock = pullRequest;

      for (int i = 0; i < 2; i++) {
        unawaited(pubsub.publish(
          'auto-submit-comment-sub',
          mergeCommentMessage,
        ));
      }

      pullRequestMergeUpdate = MergeUpdatePullRequest(
        config: config,
        cronAuthProvider: auth,
        pubsub: pubsub,
      );

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};

      await pullRequestMergeUpdate.get();

      // Verify that processed what we think we processed.
      githubService.verifyBranchUpdates(expectedMergeRequestMap);

      expect(
        0,
        pubsub.messagesQueue.length,
      );
    });

    test('Wrong authorAssociation is not processed', () async {
      // Need to add a pullrequest to the pullRequestMock in the FakeGithubService.
      final RepositorySlug slug = RepositorySlug(
        'ricardoamador',
        'flutter_test',
      );
      final PullRequest pullRequest = PullRequest(
        state: 'open',
        mergeable: true,
      );

      final MergeCommentMessage mergeCommentMessage = generateMergeCommentMessage(
        authorAssociation: 'ASSOCIATE',
        addPullRequest: true,
        slug: slug,
      );

      final IssueComment issueComment = mergeCommentMessage.comment!;
      githubService.issueCommentMock = issueComment;

      gitReferenceMock = GitReference.fromJson(json.decode(gitReference) as Map<String, dynamic>);
      githubService.gitReferenceMock = gitReferenceMock;
      githubService.useRealComment = true;
      githubService.pullRequestMock = pullRequest;

      for (int i = 0; i < 2; i++) {
        unawaited(pubsub.publish(
          'auto-submit-comment-sub',
          mergeCommentMessage,
        ));
      }

      pullRequestMergeUpdate = MergeUpdatePullRequest(
        config: config,
        cronAuthProvider: auth,
        pubsub: pubsub,
      );

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};

      await pullRequestMergeUpdate.get();

      // Verify that processed what we think we processed.
      githubService.verifyBranchUpdates(expectedMergeRequestMap);

      expect(
        0,
        pubsub.messagesQueue.length,
      );
    });
  });
}

MergeCommentMessage generateMergeCommentMessage({
  String? authorAssociation,
  String? commentBody,
  bool addPullRequest = false,
  RepositorySlug? slug,
  String? issueState,
}) {
  const String pullRequestJson = '''
    "pull_request": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/pulls/9",
      "html_url": "https://github.com/ricardoamador/flutter_test/pull/9",
      "diff_url": "https://github.com/ricardoamador/flutter_test/pull/9.diff",
      "patch_url": "https://github.com/ricardoamador/flutter_test/pull/9.patch",
      "merged_at": null
    },
''';

  final String pullRequest = addPullRequest ? pullRequestJson : '';
  slug ??= RepositorySlug(
    'flutter',
    'cocoon',
  );
  authorAssociation ??= 'OWNER';
  commentBody ??= '@autosubmit:merge';
  issueState ??= 'open';

  return MergeCommentMessage.fromJson(
    jsonDecode('''
{
  "issue": {
    "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/10",
    "id": 1578819463,
    "node_id": "I_kwDOIRxr_M5eGt-H",
    "number": 10,
    "title": "Test issue to see if these differ from pull requests via github.",
    "user": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "type": "User",
      "site_admin": false,
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "html_url": "https://github.com/apps/revert"
    },
    "state": "$issueState",
    "locked": false,
    "assignee": null,
    "assignees": [
    ],
    "milestone": null,
    "comments": 1,
    "created_at": "2023-02-10T00:44:37Z",
    "updated_at": "2023-02-10T00:45:07Z",
    "closed_at": null,
    "author_association": "$authorAssociation",
    "active_lock_reason": null,
    "body": null,
    "draft": false,
    $pullRequest
    "performed_via_github_app": null,
    "state_reason": null
  },
  "comment": {
    "id": 1425024464,
    "node_id": "IC_kwDOIRxr_M5U8CXQ",
    "user": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "type": "User",
      "site_admin": false,
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "html_url": "https://github.com/apps/revert"
    },
    "created_at": "2023-02-10T00:45:07Z",
    "updated_at": "2023-02-10T00:45:07Z",
    "author_association": "$authorAssociation",
    "body": "$commentBody.",
    "performed_via_github_app": null
  },
  "repository": {
    "id": 555510780,
    "node_id": "R_kgDOIRxr_A",
    "name": "${slug.name}",
    "full_name": "${slug.fullName}",
    "private": true,
    "owner": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "type": "User",
      "site_admin": false,
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "html_url": "https://github.com/apps/revert"
    },
    "description": "Test repository for checking git commands",
    "default_branch": "main"
  }
}
'''),
  );
}
