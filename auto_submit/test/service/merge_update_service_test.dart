// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

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
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);

    mergeUpdateService = MergeUpdateService(config);
    slug = RepositorySlug('flutter', 'cocoon');

    gitReferenceMock = GitReference.fromJson(json.decode(gitReference) as Map<String, dynamic>);
    githubService.gitReferenceMock = gitReferenceMock;
  });

  test('Non member/owner comment is ignored', () async {
    githubService.useRealComment = true;
    final IssueComment issueComment = IssueComment(authorAssociation: 'CONTRIBUTOR');
    await mergeUpdateService.processMessage(slug, 1, issueComment, '1', FakePubSub());
    expect(githubService.issueComment, isNotNull);
    expect(githubService.issueComment!.body!, 'You must be a MEMBER or OWNER author to request a merge update.');
  });

  test('Valid comment is processed', () async {
    githubService.useRealComment = true;
    final IssueComment issueComment = IssueComment(authorAssociation: 'MEMBER');
    await mergeUpdateService.processMessage(slug, 1, issueComment, '1', FakePubSub());
    expect(githubService.issueComment, isNotNull);
    expect(githubService.issueComment!.body!.contains('Successfully merged'), isTrue);
  });

  test('Valid comment but merge could not process', () async {
    githubService.updateBranchValue = false;
    githubService.useRealComment = true;
    final IssueComment issueComment = IssueComment(authorAssociation: 'MEMBER');
    await mergeUpdateService.processMessage(slug, 1, issueComment, '1', FakePubSub());
    expect(githubService.issueComment, isNotNull);
    expect(githubService.issueComment!.body!.contains('Unable to merge'), isTrue);
  });
}
