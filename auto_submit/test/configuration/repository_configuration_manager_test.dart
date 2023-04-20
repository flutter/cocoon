// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/configuration/repository_configuration_manager.dart';
import 'package:github/github.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';

void main() {
  late RepositoryConfigurationManager repositoryConfigurationManager;
  late CacheProvider cacheProvider;
  late Cache cache;

  late FakeGithubService githubService;
  late FakeConfig config;

  setUp(() {
    cacheProvider = Cache.inMemoryCacheProvider(5);
    cache = Cache<dynamic>(cacheProvider).withPrefix('config');
    githubService = FakeGithubService();
    config = FakeConfig(githubService: githubService);
    repositoryConfigurationManager = RepositoryConfigurationManager(config, cache);
  });

  test('Verify cache storage', () async {
    const String sampleConfig = '''
      default_branch: main
      issues_repository:
        owner: flutter
        repo: flutter
      auto_approval_accounts:
        - dependabot[bot]
        - dependabot
        - DartDevtoolWorkflowBot
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns_on_revert:
        - “ci.yaml validation”
        - “Google-testing”
    ''';

    githubService.fileContentsMockList.add(sampleConfig);
    final RepositoryConfiguration repositoryConfiguration =
        await repositoryConfigurationManager.readRepositoryConfiguration(
      RepositorySlug('flutter', 'cocoon'),
    );

    expect(repositoryConfiguration.allowConfigOverride, isFalse);
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.issuesRepository!.fullName, 'flutter/flutter');
    expect(repositoryConfiguration.autoApprovalAccounts!.isNotEmpty, isTrue);
    expect(repositoryConfiguration.autoApprovalAccounts!.length, 3);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.approvalGroup, 'flutter-hackers');
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert!.isNotEmpty, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert!.length, 2);
  });

  test('Omitted issues_repository assumes provided slug is for issues', () async {
    const String sampleConfig = '''
      default_branch: main
      auto_approval_accounts:
        - dependabot[bot]
        - dependabot
        - DartDevtoolWorkflowBot
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns_on_revert:
        - “ci.yaml validation”
        - “Google-testing”
    ''';

    githubService.fileContentsMockList.add(sampleConfig);
    final RepositoryConfiguration repositoryConfiguration =
        await repositoryConfigurationManager.readRepositoryConfiguration(
      RepositorySlug('flutter', 'cocoon'),
    );

    expect(repositoryConfiguration.allowConfigOverride, isFalse);
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.issuesRepository!.fullName, 'flutter/cocoon');
    expect(repositoryConfiguration.autoApprovalAccounts!.isNotEmpty, isTrue);
    expect(repositoryConfiguration.autoApprovalAccounts!.length, 3);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.approvalGroup, 'flutter-hackers');
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert!.isNotEmpty, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert!.length, 2);
  });

  test('Default branch collected if omitted', () async {
    const String sampleConfig = '''
      auto_approval_accounts:
        - dependabot[bot]
        - dependabot
        - DartDevtoolWorkflowBot
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns_on_revert:
        - “ci.yaml validation”
        - “Google-testing”
    ''';

    githubService.fileContentsMockList.add(sampleConfig);
    githubService.defaultBranch = 'main';
    final RepositoryConfiguration repositoryConfiguration =
        await repositoryConfigurationManager.readRepositoryConfiguration(
      RepositorySlug('flutter', 'cocoon'),
    );

    expect(repositoryConfiguration.allowConfigOverride, isFalse);
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.issuesRepository!.fullName, 'flutter/cocoon');
    expect(repositoryConfiguration.autoApprovalAccounts!.isNotEmpty, isTrue);
    expect(repositoryConfiguration.autoApprovalAccounts!.length, 3);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.approvalGroup, 'flutter-hackers');
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert!.isNotEmpty, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert!.length, 2);
  });
}
