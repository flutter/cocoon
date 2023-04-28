// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/exception/configuration_exception.dart';
import 'package:yaml/yaml.dart';

/// The RepositoryConfiguration stores the pertinent information that autosubmit
/// will need when submiting and validating pull requests for a particular
/// repository.
class RepositoryConfiguration {
  // Autosubmit configuration keys as found in the yaml configuraiton file.
  static const String allowConfigOverrideKey = 'allow_config_override';
  static const String defaultBranchKey = 'default_branch';
  static const String autoApprovalAccountsKey = 'auto_approval_accounts';
  static const String approvingReviewsKey = 'approving_reviews';
  static const String approvalGroupKey = 'approval_group';
  static const String runCiKey = 'run_ci';
  static const String supportNoReviewRevertKey = 'support_no_review_revert';
  static const String requiredCheckRunsOnRevertKey = 'required_checkruns_on_revert';

  RepositoryConfiguration({
    this.allowConfigOverride,
    this.defaultBranch,
    this.autoApprovalAccounts,
    this.approvingReviews,
    this.approvalGroup,
    this.runCi,
    this.supportNoReviewReverts,
    this.requiredCheckRunsOnRevert,
  });

  /// This flag allows the repository to override the org level configuration.
  bool? allowConfigOverride;

  /// The default branch that pull requests will be merged into.
  String? defaultBranch;

  /// The accounts that have auto approval on their pull requests.
  Set<String>? autoApprovalAccounts;

  /// The number of reviews needed for a pull request. If the reviewer is part
  /// of the approval group they will need ([approvingReviews] - 1) number of
  /// reviews in order to merge the pull request, if they are not part of the
  /// approval group the will need [approvingReviews] number of reviews.
  int? approvingReviews;

  /// The group that the pull request author will need pull requests from.
  String? approvalGroup;

  /// Flag to determine whether or not to wait for all the ci checks to finish
  /// before allowing a merge of the pull request.
  bool? runCi;

  /// Flag that determines if reverts are allowed without a review.
  bool? supportNoReviewReverts;

  /// Set of checkruns that must complete before a revert pull request can be
  /// merged.
  Set<String>? requiredCheckRunsOnRevert;

  @override
  String toString() {
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln('$allowConfigOverrideKey: $allowConfigOverride');
    stringBuffer.writeln('$defaultBranchKey: $defaultBranch');
    stringBuffer.writeln('$autoApprovalAccountsKey:');
    for (String account in autoApprovalAccounts!) {
      stringBuffer.writeln('  - $account');
    }
    stringBuffer.writeln('$approvingReviewsKey: $approvingReviews');
    stringBuffer.writeln('$approvalGroupKey: $approvalGroup');
    stringBuffer.writeln('$runCiKey: $runCi');
    stringBuffer.writeln('$supportNoReviewRevertKey: $supportNoReviewReverts');
    stringBuffer.writeln('$requiredCheckRunsOnRevertKey:');
    for (String checkrun in requiredCheckRunsOnRevert!) {
      stringBuffer.writeln('  - $checkrun');
    }
    return stringBuffer.toString();
  }

  static RepositoryConfiguration fromYaml(String yaml) {
    final dynamic yamlDoc = loadYaml(yaml);

    final Set<String> autoApprovalAccounts = {};
    final YamlList? yamlAutoApprovalAccounts = yamlDoc[autoApprovalAccountsKey];
    if (yamlAutoApprovalAccounts != null) {
      for (var element in yamlAutoApprovalAccounts) {
        autoApprovalAccounts.add(element as String);
      }
    }
    
    if (yamlDoc[approvalGroupKey] == null) {
      throw ConfigurationException('The approval group is a required field.');
    }

    final Set<String> requiredCheckRunsOnRevert = {};
    final YamlList? yamlRequiredCheckRuns = yamlDoc[requiredCheckRunsOnRevertKey];
    if (yamlRequiredCheckRuns != null) {
      for (var element in yamlRequiredCheckRuns) {
        requiredCheckRunsOnRevert.add(element as String);
      }
    }

    return RepositoryConfiguration(
      allowConfigOverride: yamlDoc[allowConfigOverrideKey] ?? false,
      defaultBranch: yamlDoc[defaultBranchKey] ?? 'main',
      autoApprovalAccounts: autoApprovalAccounts,
      approvingReviews: yamlDoc[approvingReviewsKey] ?? 2,
      approvalGroup: yamlDoc[approvalGroupKey],
      runCi: yamlDoc[runCiKey] ?? true,
      supportNoReviewReverts: yamlDoc[supportNoReviewRevertKey] ?? true,
      requiredCheckRunsOnRevert: requiredCheckRunsOnRevert,
    );
  }
}
