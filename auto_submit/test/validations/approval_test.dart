// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/approval.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:test/test.dart';

import 'package:github/github.dart' as gh;
import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/mocks.mocks.dart';
import 'approval_test_data.dart';

void main() {
  late Approval approval;
  late FakeConfig config;
  final FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  final MockGitHub gitHub = MockGitHub();

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
    approval = Approval(config: config);
  });

  group('Approval group tests', () {
    Future<ValidationResult> computeValidationResult(String review) async {
      final Map<String, dynamic> queryResultJsonDecode = jsonDecode(review) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      final gh.PullRequest pullRequest = generatePullRequest();
      return approval.validate(queryResult, pullRequest);
    }

    test('Author and reviewer in flutter-hackers, pr approved', () async {
      // TODO(ricardoamador) this does not matter much now that we check group membership,
      // remove and refactor.
      final String review = constructSingleReviewerReview(
        authorAuthorAssociation: 'MEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        reviewState: 'APPROVED',
      );

      githubService.isTeamMemberMockList = [true, true];
      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isTrue);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has met approval requirements for merging.'), isTrue);
    });

    test('Author is a NON member and reviewer is a member, need 1 more review', () async {
      githubService.isTeamMemberMockList = [false, true];
      final String review = constructSingleReviewerReview(
        authorAuthorAssociation: 'NONMEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        reviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('need 1 more review'), isTrue);
    });

    test('Author is a NON member and reviewer is a NON member, need 2 more reviews', () async {
      githubService.isTeamMemberMockList = [false, false];
      final String review = constructSingleReviewerReview(
        authorAuthorAssociation: 'NONMEMBER',
        reviewerAuthorAssociation: 'NONMEMBER',
        reviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('need 2 more review'), isTrue);
    });

    test('Author is a member and reviewer is NON member, need 1 more review', () async {
      githubService.isTeamMemberMockList = [true, false];
      final String review = constructSingleReviewerReview(
        authorAuthorAssociation: 'MEMBER',
        reviewerAuthorAssociation: 'NONMEMBER',
        reviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('need 1 more review'), isTrue);
    });

    test('Author is NON member and reviewers are members, pr approved', () async {
      githubService.isTeamMemberMockList = [false, true, true];
      final String review = constructTwoReviewerReview(
        authorAuthorAssociation: 'NONMEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        secondReviewerAuthorAssociation: 'OWNER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isTrue);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has met approval requirements for merging.'), isTrue);
    });

    test('Author is NON member and one reviewer is a NON member, need 1 more review', () async {
      githubService.isTeamMemberMockList = [false, true, false];
      final String review = constructTwoReviewerReview(
        authorAuthorAssociation: 'NONMEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        secondReviewerAuthorAssociation: 'NONMEMBER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('need 1 more review'), isTrue);
    });

    test('Author is member and reviewers are NON members, need 1 more review', () async {
      githubService.isTeamMemberMockList = [true, false, false];
      final String review = constructTwoReviewerReview(
        authorAuthorAssociation: 'MEMBER',
        reviewerAuthorAssociation: 'NONMEMBER',
        secondReviewerAuthorAssociation: 'NONMEMBER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('need 1 more review'), isTrue);
    });

    test('Author is NON member and reviewers are NON members, need 2 reviews', () async {
      githubService.isTeamMemberMockList = [false, false, false];
      final String review = constructTwoReviewerReview(
        authorAuthorAssociation: 'NONMEMBER',
        reviewerAuthorAssociation: 'NONMEMBER',
        secondReviewerAuthorAssociation: 'NONMEMBER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('need 2 more review'), isTrue);
    });

    test('Verify author review count does not go negative', () async {
      githubService.isTeamMemberMockList = [false, false, false, false];
      final String review = constructMultipleReviewerReview(
        authorAuthorAssociation: 'NONMEMBER',
        reviewerAuthorAssociation: 'NONMEMBER',
        secondReviewerAuthorAssociation: 'NONMEMBER',
        thirdReviewerAuthorAssociation: 'NONMEMBER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
        thirdReviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('need 2 more review'), isTrue);
    });

    test('Verify author review count does not go negative', () async {
      githubService.isTeamMemberMockList = [true, true, true, true];
      final String review = constructMultipleReviewerReview(
        authorAuthorAssociation: 'MEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        secondReviewerAuthorAssociation: 'MEMBER',
        thirdReviewerAuthorAssociation: 'MEMBER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
        thirdReviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isTrue);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has met approval requirements for merging.'), isTrue);
    });

    test('Author is member and member requests changes, 1 review is needed', () async {
      githubService.isTeamMemberMockList = [true, true];
      final String review = constructSingleReviewerReview(
        authorAuthorAssociation: 'MEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        reviewState: 'CHANGES_REQUESTED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('Changes were requested by'), isTrue);
    });

    test('Author is member and two member reviews, 1 change request, review is not approved', () async {
      githubService.isTeamMemberMockList = [true, true, true];
      final String review = constructTwoReviewerReview(
        authorAuthorAssociation: 'MEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        secondReviewerAuthorAssociation: 'MEMBER',
        reviewState: 'CHANGES_REQUESTED',
        secondReviewState: 'APPROVED',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging.'), isTrue);
      expect(result.message.contains('Changes were requested by'), isTrue);
    });

    test('Multiple approving reviews from the same author are counted only 1 time.', () async {
      githubService.isTeamMemberMockList = [false, true, true];
      final String review = constructTwoReviewerReview(
        authorAuthorAssociation: 'CONTRIBUTOR',
        reviewerAuthorAssociation: 'MEMBER',
        secondReviewerAuthorAssociation: 'MEMBER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
        author: 'ricardoamador',
        secondAuthor: 'ricardoamador',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message.contains(
          'This PR has not met approval requirements for merging. You have project association CONTRIBUTOR and need 1 more review(s) in order to merge this PR.',
        ),
        isTrue,
      );
    });

    test('Successful review overwrites previous changes requested.', () async {
      githubService.isTeamMemberMockList = [true, true, true, true, true, true];
      final ValidationResult result = await computeValidationResult(multipleReviewsSameAuthor);

      expect(result.result, isTrue);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has met approval requirements for merging.'), isTrue);
    });

    test('Author cannot review own pr', () async {
      githubService.isTeamMemberMockList = [true, false, true];
      final String review = constructTwoReviewerReview(
        authorAuthorAssociation: 'MEMBER',
        reviewerAuthorAssociation: 'MEMBER',
        secondReviewerAuthorAssociation: 'NON_MEMBER',
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
        author: 'author1',
      );

      final ValidationResult result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(result.message.contains('This PR has not met approval requirements for merging. You have'), isTrue);
    });
  });
}
