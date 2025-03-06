// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/approval.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:cocoon_server/testing/mocks.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import 'approval_test_data.dart';

void main() {
  late Approval approval;
  late FakeConfig config;
  final githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  final gitHub = MockGitHub();

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(
      githubService: githubService,
      githubGraphQLClient: githubGraphQLClient,
      githubClient: gitHub,
    );
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
      sampleConfigNoOverride,
    );
    approval = Approval(config: config);
  });

  group('Approval group tests', () {
    Future<ValidationResult> computeValidationResult(String review) async {
      final queryResultJsonDecode = jsonDecode(review) as Map<String, dynamic>;
      final queryResult = QueryResult.fromJson(queryResultJsonDecode);
      final pullRequest = generatePullRequest();
      return approval.validate(queryResult, pullRequest);
    }

    test('Author and reviewer in flutter-hackers, pr approved', () async {
      final review = constructSingleReviewerReview(reviewState: 'APPROVED');

      // githubService.isTeamMemberMockList = [true, true];
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.isTeamMemberMockMap['keyonghan'] = true;
      final result = await computeValidationResult(review);

      expect(result.result, isTrue);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message.contains(
          'This PR has met approval requirements for merging.',
        ),
        isTrue,
      );
    });

    test(
      'Author is a NON member and reviewer is a member, needs 1 more review',
      () async {
        // githubService.isTeamMemberMockList = [true, true];
        githubService.isTeamMemberMockMap['author1'] = false;
        githubService.isTeamMemberMockMap['keyonghan'] = true;
        final review = constructSingleReviewerReview(reviewState: 'APPROVED');

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('needs 1 more review'), isTrue);
      },
    );

    test(
      'Author is a NON member and reviewer is a NON member, needs 2 more reviews',
      () async {
        // githubService.isTeamMemberMockList = [true, true];
        githubService.isTeamMemberMockMap['author1'] = false;
        githubService.isTeamMemberMockMap['keyonghan'] = false;
        final review = constructSingleReviewerReview(reviewState: 'APPROVED');

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('needs 2 more review'), isTrue);
      },
    );

    test(
      'Author is a member and reviewer is NON member, needs 1 more review',
      () async {
        // githubService.isTeamMemberMockList = [true, true];
        githubService.isTeamMemberMockMap['author1'] = true;
        githubService.isTeamMemberMockMap['keyonghan'] = false;
        final review = constructSingleReviewerReview(reviewState: 'APPROVED');

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.IGNORE_TEMPORARILY);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('needs 1 more review'), isTrue);
      },
    );

    test(
      'Author is NON member and reviewers are members, pr approved',
      () async {
        githubService.isTeamMemberMockMap['author1'] = false;
        githubService.isTeamMemberMockMap['author2'] = true;
        githubService.isTeamMemberMockMap['author3'] = true;
        final review = constructTwoReviewerReview(
          reviewState: 'APPROVED',
          secondReviewState: 'APPROVED',
        );

        final result = await computeValidationResult(review);

        expect(result.result, isTrue);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has met approval requirements for merging.',
          ),
          isTrue,
        );
      },
    );

    test(
      'Author is NON member and one reviewer is a NON member, needs 1 more review',
      () async {
        githubService.isTeamMemberMockMap['author1'] = false;
        githubService.isTeamMemberMockMap['author2'] = true;
        githubService.isTeamMemberMockMap['author3'] = false;
        final review = constructTwoReviewerReview(
          reviewState: 'APPROVED',
          secondReviewState: 'APPROVED',
        );

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('needs 1 more review'), isTrue);
      },
    );

    test(
      'Author is member and reviewers are NON members, needs 1 more review',
      () async {
        githubService.isTeamMemberMockMap['author1'] = true;
        githubService.isTeamMemberMockMap['author2'] = false;
        githubService.isTeamMemberMockMap['author3'] = false;
        final review = constructTwoReviewerReview(
          reviewState: 'APPROVED',
          secondReviewState: 'APPROVED',
        );

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.IGNORE_TEMPORARILY);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('needs 1 more review'), isTrue);
      },
    );

    test(
      'Author is NON member and reviewers are NON members, needs 2 reviews',
      () async {
        githubService.isTeamMemberMockMap['author1'] = false;
        githubService.isTeamMemberMockMap['author2'] = false;
        githubService.isTeamMemberMockMap['author3'] = false;
        final review = constructTwoReviewerReview(
          reviewState: 'APPROVED',
          secondReviewState: 'APPROVED',
        );

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('needs 2 more review'), isTrue);
      },
    );

    test('Verify author review count does not go negative', () async {
      githubService.isTeamMemberMockMap['author1'] = false;
      githubService.isTeamMemberMockMap['ricardoamador'] = false;
      githubService.isTeamMemberMockMap['keyonghan'] = false;
      githubService.isTeamMemberMockMap['nehalvpatel'] = false;
      final review = constructMultipleReviewerReview(
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
        thirdReviewState: 'APPROVED',
      );

      final result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message.contains(
          'This PR has not met approval requirements for merging.',
        ),
        isTrue,
      );
      expect(result.message.contains('needs 2 more review'), isTrue);
    });

    test('Verify author review count does not go negative', () async {
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.isTeamMemberMockMap['ricardoamador'] = true;
      githubService.isTeamMemberMockMap['keyonghan'] = true;
      githubService.isTeamMemberMockMap['nehalvpatel'] = true;
      final review = constructMultipleReviewerReview(
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
        thirdReviewState: 'APPROVED',
      );

      final result = await computeValidationResult(review);

      expect(result.result, isTrue);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message.contains(
          'This PR has met approval requirements for merging.',
        ),
        isTrue,
      );
    });

    test(
      'Author is member and member requests changes, 1 review is needed',
      () async {
        githubService.isTeamMemberMockMap['author1'] = true;
        githubService.isTeamMemberMockMap['keyonghan'] = true;
        final review = constructSingleReviewerReview(
          reviewState: 'CHANGES_REQUESTED',
        );

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('Changes were requested by'), isTrue);
      },
    );

    test(
      'Author is member and two member reviews, 1 change request, review is not approved',
      () async {
        githubService.isTeamMemberMockMap['author1'] = true;
        githubService.isTeamMemberMockMap['author2'] = true;
        githubService.isTeamMemberMockMap['author3'] = true;
        final review = constructTwoReviewerReview(
          reviewState: 'CHANGES_REQUESTED',
          secondReviewState: 'APPROVED',
        );

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging.',
          ),
          isTrue,
        );
        expect(result.message.contains('Changes were requested by'), isTrue);
      },
    );

    test(
      'Multiple approving reviews from the same author are counted only 1 time.',
      () async {
        githubService.isTeamMemberMockMap['author1'] = false;
        githubService.isTeamMemberMockMap['ricardoamador'] = true;
        final review = constructTwoReviewerReview(
          reviewState: 'APPROVED',
          secondReviewState: 'APPROVED',
          author: 'ricardoamador',
          secondAuthor: 'ricardoamador',
        );

        final result = await computeValidationResult(review);

        expect(result.result, isFalse);
        expect(result.action, Action.REMOVE_LABEL);
        expect(
          result.message.contains(
            'This PR has not met approval requirements for merging. The PR author is not a member of flutter-hackers and needs 1 more review(s) in order to merge this PR.',
          ),
          isTrue,
        );
      },
    );

    test('Successful review overwrites previous changes requested.', () async {
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.isTeamMemberMockMap['keyonghan'] = true;
      githubService.isTeamMemberMockMap['jmagman'] = true;
      final result = await computeValidationResult(multipleReviewsSameAuthor);

      expect(result.result, isTrue);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message.contains(
          'This PR has met approval requirements for merging.',
        ),
        isTrue,
      );
    });

    test('Author cannot review own pr', () async {
      githubService.isTeamMemberMockMap['author1'] = false;
      githubService.isTeamMemberMockMap['author3'] = true;
      final review = constructTwoReviewerReview(
        reviewState: 'APPROVED',
        secondReviewState: 'APPROVED',
        author: 'author1',
      );

      final result = await computeValidationResult(review);

      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message.contains(
          'This PR has not met approval requirements for merging. The PR author is not a member of flutter-hackers',
        ),
        isTrue,
      );
    });
  });
}
