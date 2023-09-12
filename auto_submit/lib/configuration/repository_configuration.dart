// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/exception/configuration_exception.dart';
import 'package:yaml/yaml.dart';

/// The RepositoryConfiguration stores the pertinent information that autosubmit
/// will need when submiting and validating pull requests for a particular
/// repository.
class RepositoryConfiguration {
  // Autosubmit configuration keys as found in the both the global and local
  // yaml configuraiton files.
  static const String allowConfigOverrideKey = 'allow_config_override';
  static const String defaultBranchKey = 'default_branch';
  static const String autoApprovalAccountsKey = 'auto_approval_accounts';
  static const String approvingReviewsKey = 'approving_reviews';
  static const String approvalGroupKey = 'approval_group';
  static const String runCiKey = 'run_ci';
  static const String supportNoReviewRevertKey = 'support_no_review_revert';
  static const String requiredCheckRunsOnRevertKey = 'required_checkruns_on_revert';

  // Default values
  static const bool allowConfigOverrideDefault = false;
  static const String defaultBranchDefault = 'main';
  static const Set<String> autoApprovalAccountsDefault = <String>{};
  static const int approvingReviewsDefault = 2;
  static const String approvalGroupDefault = 'flutter-hackers';
  static const bool runCiDefault = true;
  static const bool supportNoReviewRevertsDefault = true;
  static const Set<String> requiredCheckRunsOnRevertDefault = <String>{};

  RepositoryConfiguration({
    allowConfigOverride,
    defaultBranch,
    autoApprovalAccounts,
    approvingReviews,
    approvalGroup,
    runCi,
    supportNoReviewReverts,
    requiredCheckRunsOnRevert,
  })  : allowConfigOverride = allowConfigOverride ?? false,
        defaultBranch = defaultBranch ?? 'main',
        autoApprovalAccounts = autoApprovalAccounts ?? <String>{},
        approvingReviews = approvingReviews ?? 2,
        approvalGroup = approvalGroup ?? 'flutter-hackers',
        runCi = runCi ?? true,
        supportNoReviewReverts = supportNoReviewReverts ?? true,
        requiredCheckRunsOnRevert = requiredCheckRunsOnRevert ?? <String>{};

  /// This flag allows the repository to override the org level configuration.
  bool allowConfigOverride;

  /// The default branch that pull requests will be merged into.
  String defaultBranch;

  /// The accounts that have auto approval on their pull requests.
  Set<String> autoApprovalAccounts;

  /// The number of reviews needed for a pull request. If the reviewer is part
  /// of the approval group they will need ([approvingReviews] - 1) number of
  /// reviews in order to merge the pull request, if they are not part of the
  /// approval group the will need [approvingReviews] number of reviews.
  int approvingReviews;

  /// The group that the pull request author will need pull requests from.
  String approvalGroup;

  /// Flag to determine whether or not to wait for all the ci checks to finish
  /// before allowing a merge of the pull request.
  bool runCi;

  /// Flag that determines if reverts are allowed without a review.
  bool supportNoReviewReverts;

  /// Set of checkruns that must complete before a revert pull request can be
  /// merged.
  Set<String> requiredCheckRunsOnRevert;

  @override
  String toString() {
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln('$allowConfigOverrideKey: $allowConfigOverride');
    stringBuffer.writeln('$defaultBranchKey: $defaultBranch');
    stringBuffer.writeln('$autoApprovalAccountsKey:');
    for (String account in autoApprovalAccounts) {
      stringBuffer.writeln('  - $account');
    }
    stringBuffer.writeln('$approvingReviewsKey: $approvingReviews');
    stringBuffer.writeln('$approvalGroupKey: $approvalGroup');
    stringBuffer.writeln('$runCiKey: $runCi');
    stringBuffer.writeln('$supportNoReviewRevertKey: $supportNoReviewReverts');
    stringBuffer.writeln('$requiredCheckRunsOnRevertKey:');
    for (String checkrun in requiredCheckRunsOnRevert) {
      stringBuffer.writeln('  - $checkrun');
    }
    return stringBuffer.toString();
  }

  static RepositoryConfiguration fromYaml(String yaml) {
    final dynamic yamlDoc = loadYaml(yaml);

    // TODO (ricardoamador) for testing purposes remove from here and add to config under auto_approval_accounts
    // We need both the auto-submit[bot] and auto-submit names due to the differences between the
    // REST API and the stupid graphql api.
    final Set<String> autoApprovalAccounts = <String>{'auto-submit[bot]', 'auto-submit'};
    // final Set<String> autoApprovalAccounts = <String>{};
    final YamlList? yamlAutoApprovalAccounts = yamlDoc[autoApprovalAccountsKey];
    if (yamlAutoApprovalAccounts != null) {
      for (YamlNode element in yamlAutoApprovalAccounts.nodes) {
        autoApprovalAccounts.add(element.value as String);
      }
    }

    if (yamlDoc[approvalGroupKey] == null) {
      throw ConfigurationException('The approval group is a required field.');
    }

    final Set<String> requiredCheckRunsOnRevert = <String>{};
    final YamlList? yamlRequiredCheckRuns = yamlDoc[requiredCheckRunsOnRevertKey];
    if (yamlRequiredCheckRuns != null) {
      for (YamlNode element in yamlRequiredCheckRuns.nodes) {
        requiredCheckRunsOnRevert.add(element.value as String);
      }
    }

    return RepositoryConfiguration(
      allowConfigOverride: yamlDoc[allowConfigOverrideKey],
      defaultBranch: yamlDoc[defaultBranchKey],
      autoApprovalAccounts: autoApprovalAccounts,
      approvingReviews: yamlDoc[approvingReviewsKey],
      approvalGroup: yamlDoc[approvalGroupKey],
      runCi: yamlDoc[runCiKey],
      supportNoReviewReverts: yamlDoc[supportNoReviewRevertKey],
      requiredCheckRunsOnRevert: requiredCheckRunsOnRevert,
    );
  }
}
