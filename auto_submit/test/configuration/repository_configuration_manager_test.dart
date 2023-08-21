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
import 'repository_configuration_data.dart';

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
      auto_approval_accounts:
        - dependabot[bot]
        - dependabot
        - DartDevtoolWorkflowBot
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns_on_revert:
        - ci.yaml validation
        - Google-testing
        - test (ubuntu-latest, 2.18.0)
        - cla/google
    ''';

    githubService.fileContentsMockList.add(sampleConfig);
    final RepositoryConfiguration repositoryConfiguration =
        await repositoryConfigurationManager.readRepositoryConfiguration(
      RepositorySlug('flutter', 'cocoon'),
    );

    expect(repositoryConfiguration.allowConfigOverride, isFalse);
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.autoApprovalAccounts.isNotEmpty, isTrue);
    // TODO this change can stay as the autosubmit bot account will eventually be
    // added to the configuration.
    expect(repositoryConfiguration.autoApprovalAccounts.length, 4);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.approvalGroup, 'flutter-hackers');
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.isNotEmpty, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.length, 4);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("ci.yaml validation"), isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("Google-testing"), isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("test (ubuntu-latest, 2.18.0)"), isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("cla/google"), isTrue);
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
        - ci.yaml validation
        - Google-testing
    ''';

    githubService.fileContentsMockList.add(sampleConfig);
    final RepositoryConfiguration repositoryConfiguration =
        await repositoryConfigurationManager.readRepositoryConfiguration(
      RepositorySlug('flutter', 'cocoon'),
    );

    expect(repositoryConfiguration.allowConfigOverride, isFalse);
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.autoApprovalAccounts.isNotEmpty, isTrue);
    expect(repositoryConfiguration.autoApprovalAccounts.length, 4);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.approvalGroup, 'flutter-hackers');
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.isNotEmpty, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.length, 2);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("ci.yaml validation"), isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("Google-testing"), isTrue);
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
        - ci.yaml validation
        - Google-testing
    ''';

    githubService.fileContentsMockList.add(sampleConfig);
    githubService.defaultBranch = 'main';
    final RepositoryConfiguration repositoryConfiguration =
        await repositoryConfigurationManager.readRepositoryConfiguration(
      RepositorySlug('flutter', 'cocoon'),
    );

    expect(repositoryConfiguration.allowConfigOverride, isFalse);
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.autoApprovalAccounts.isNotEmpty, isTrue);
    expect(repositoryConfiguration.autoApprovalAccounts.length, 4);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.approvalGroup, 'flutter-hackers');
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.isNotEmpty, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.length, 2);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("ci.yaml validation"), isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.contains("Google-testing"), isTrue);
  });

  group('Merging configurations tests', () {
    // Sample configuration being used for these tests
    /*
      default_branch: main
      allow_config_override: true
      auto_approval_accounts:
        - dependabot[bot]
        - dependabot
        - DartDevtoolWorkflowBot
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns_on_revert:
        - ci.yaml validation
    */

    test('Global config merged with default local config', () {
      final RepositoryConfiguration localRepositoryConfiguration = RepositoryConfiguration();
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(mergedRepositoryConfiguration.defaultBranch, 'main');
      expect(mergedRepositoryConfiguration.allowConfigOverride, isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.length, 4);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('dependabot[bot]'), isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('dependabot'), isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('DartDevtoolWorkflowBot'), isTrue);
      expect(mergedRepositoryConfiguration.approvingReviews, 2);
      expect(mergedRepositoryConfiguration.runCi, isTrue);
      expect(mergedRepositoryConfiguration.supportNoReviewReverts, isTrue);
      expect(mergedRepositoryConfiguration.requiredCheckRunsOnRevert.length, 1);
      expect(mergedRepositoryConfiguration.requiredCheckRunsOnRevert.contains('ci.yaml validation'), isTrue);
    });

    test('Auto approval accounts is additive, they cannot be removed', () {
      const String expectedAddedApprovalAccount = 'flutter-roller-account';
      const Set<String> localAutoApprovalAccounts = {expectedAddedApprovalAccount};
      final RepositoryConfiguration localRepositoryConfiguration =
          RepositoryConfiguration(autoApprovalAccounts: localAutoApprovalAccounts);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.length, 5);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('dependabot[bot]'), isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('dependabot'), isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('DartDevtoolWorkflowBot'), isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains(expectedAddedApprovalAccount), isTrue);
    });

    test('Duplicate auto approval account is not added', () {
      const String expectedAddedApprovalAccount = 'DartDevtoolWorkflowBot';
      const Set<String> localAutoApprovalAccounts = {expectedAddedApprovalAccount};
      final RepositoryConfiguration localRepositoryConfiguration =
          RepositoryConfiguration(autoApprovalAccounts: localAutoApprovalAccounts);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.length, 4);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('dependabot[bot]'), isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('dependabot'), isTrue);
      expect(mergedRepositoryConfiguration.autoApprovalAccounts.contains('DartDevtoolWorkflowBot'), isTrue);
    });

    test('Approving reviews is overridden by local config', () {
      const int expectedApprovingReviews = 3;
      final RepositoryConfiguration localRepositoryConfiguration =
          RepositoryConfiguration(approvingReviews: expectedApprovingReviews);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(globalRepositoryConfiguration.approvingReviews != mergedRepositoryConfiguration.approvingReviews, isTrue);
      expect(mergedRepositoryConfiguration.approvingReviews, expectedApprovingReviews);
    });

    test('Approving reviews is not overridden if less than global config', () {
      const int expectedApprovingReviews = 2;
      final RepositoryConfiguration localRepositoryConfiguration = RepositoryConfiguration(approvingReviews: 1);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(globalRepositoryConfiguration.approvingReviews == mergedRepositoryConfiguration.approvingReviews, isTrue);
      expect(mergedRepositoryConfiguration.approvingReviews, expectedApprovingReviews);
    });

    test('Approval group is overridden if defined', () {
      const String expectedApprovalGroup = 'flutter-devs';
      final RepositoryConfiguration localRepositoryConfiguration =
          RepositoryConfiguration(approvalGroup: expectedApprovalGroup);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(mergedRepositoryConfiguration.approvalGroup, expectedApprovalGroup);
    });

    test('RunCi is updated if it differs from global config', () {
      const bool expectedRunCi = false;
      final RepositoryConfiguration localRepositoryConfiguration = RepositoryConfiguration(runCi: expectedRunCi);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(globalRepositoryConfiguration.runCi != mergedRepositoryConfiguration.runCi, isTrue);
      expect(mergedRepositoryConfiguration.runCi, expectedRunCi);
    });

    test('Support no review reverts is updated if it differs from global config', () {
      const bool expectedSupportNoReviewReverts = false;
      final RepositoryConfiguration localRepositoryConfiguration =
          RepositoryConfiguration(supportNoReviewReverts: expectedSupportNoReviewReverts);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(
        globalRepositoryConfiguration.supportNoReviewReverts != mergedRepositoryConfiguration.supportNoReviewReverts,
        isTrue,
      );
      expect(mergedRepositoryConfiguration.supportNoReviewReverts, expectedSupportNoReviewReverts);
    });

    test('Required check runs on revert is additive, they cannot be removed', () {
      const String expectedRequiredCheckRun = 'Linux Device Doctor Validator';
      const Set<String> localrequiredCheckRunsOnRevert = {expectedRequiredCheckRun};
      final RepositoryConfiguration localRepositoryConfiguration =
          RepositoryConfiguration(requiredCheckRunsOnRevert: localrequiredCheckRunsOnRevert);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(mergedRepositoryConfiguration.requiredCheckRunsOnRevert.length, 2);
      expect(mergedRepositoryConfiguration.requiredCheckRunsOnRevert.contains('ci.yaml validation'), isTrue);
      expect(mergedRepositoryConfiguration.requiredCheckRunsOnRevert.contains(expectedRequiredCheckRun), isTrue);
    });

    test('Duplicate required check run on revert is not added', () {
      const String expectedRequiredCheckRun = 'ci.yaml validation';
      const Set<String> localRequiredCheckRunsOnRevert = {expectedRequiredCheckRun};
      final RepositoryConfiguration localRepositoryConfiguration =
          RepositoryConfiguration(requiredCheckRunsOnRevert: localRequiredCheckRunsOnRevert);
      final RepositoryConfiguration globalRepositoryConfiguration =
          RepositoryConfiguration.fromYaml(sampleConfigWithOverride);
      final RepositoryConfiguration mergedRepositoryConfiguration = repositoryConfigurationManager.mergeConfigurations(
        globalRepositoryConfiguration,
        localRepositoryConfiguration,
      );
      expect(mergedRepositoryConfiguration.requiredCheckRunsOnRevert.length, 1);
      expect(mergedRepositoryConfiguration.requiredCheckRunsOnRevert.contains(expectedRequiredCheckRun), isTrue);
    });
  });
}
