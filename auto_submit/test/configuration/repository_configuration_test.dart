// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:test/test.dart';

void main() {
  test('Parse config from yaml', () {
    const sampleConfig = '''
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

    final repositoryConfiguration = RepositoryConfiguration.fromYaml(
      sampleConfig,
    );
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.autoApprovalAccounts.isNotEmpty, isTrue);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(
      repositoryConfiguration.requiredCheckRunsOnRevert.isNotEmpty,
      isTrue,
    );
  });

  test('Parse config from yaml excluding auto approval accounts', () {
    const sampleConfig = '''
      default_branch: main
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns_on_revert:
        - “ci.yaml validation”
        - “Google-testing”
    ''';

    final repositoryConfiguration = RepositoryConfiguration.fromYaml(
      sampleConfig,
    );
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.autoApprovalAccounts.isEmpty, isTrue);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(
      repositoryConfiguration.requiredCheckRunsOnRevert.isNotEmpty,
      isTrue,
    );
  });

  test('Parse config from yaml with empty auto_approval_accounts field', () {
    const sampleConfig = '''
      auto_approval_accounts:
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns_on_revert:
        - “ci.yaml validation”
        - “Google-testing”
    ''';

    final repositoryConfiguration = RepositoryConfiguration.fromYaml(
      sampleConfig,
    );
    // We will get the default branch later as it does not need to be added to
    // the initial configuration.
    repositoryConfiguration.defaultBranch = 'main';

    expect(repositoryConfiguration.allowConfigOverride, false);
    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.autoApprovalAccounts.isEmpty, isTrue);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(
      repositoryConfiguration.requiredCheckRunsOnRevert.isNotEmpty,
      isTrue,
    );
  });

  test('Parse minimal configuration', () {
    const sampleConfig = '''
      approval_group: flutter-hackers
      issues_repository:
        owner: flutter
        repo: flutter
    ''';

    final repositoryConfiguration = RepositoryConfiguration.fromYaml(
      sampleConfig,
    );
    repositoryConfiguration.defaultBranch = 'master';

    expect(repositoryConfiguration.defaultBranch, 'master');
    expect(repositoryConfiguration.autoApprovalAccounts.isEmpty, isTrue);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRunsOnRevert.isEmpty, isTrue);
  });
}
