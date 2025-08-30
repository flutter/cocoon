// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import '../exception/configuration_exception.dart';

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
  static const String requiredCheckRunsOnRevertKey =
      'required_checkruns_on_revert';
  static const String baseCommitAllowedDaysKey = 'base_commit_allowed_days';

  static const String defaultBranchStr = 'default';

  RepositoryConfiguration({
    bool? allowConfigOverride,
    String? defaultBranch,
    Set<String>? autoApprovalAccounts,
    int? approvingReviews,
    String? approvalGroup,
    bool? runCi,
    bool? supportNoReviewReverts,
    Set<String>? requiredCheckRunsOnRevert,
    int? baseCommitAllowedDays,
  }) : allowConfigOverride = allowConfigOverride ?? false,
       defaultBranch = defaultBranch ?? defaultBranchStr,
       autoApprovalAccounts = autoApprovalAccounts ?? <String>{},
       approvingReviews = approvingReviews ?? 2,
       approvalGroup = approvalGroup ?? 'flutter-hackers',
       runCi = runCi ?? true,
       supportNoReviewReverts = supportNoReviewReverts ?? true,
       requiredCheckRunsOnRevert = requiredCheckRunsOnRevert ?? <String>{},
       baseCommitAllowedDays = baseCommitAllowedDays ?? 0;

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

  /// The number of days that the base commit of the pull request can not be
  /// older than. If less than 1 then it will not be checked.
  int baseCommitAllowedDays;

  @override
  String toString() {
    final stringBuffer = StringBuffer();
    stringBuffer.writeln('$allowConfigOverrideKey: $allowConfigOverride');
    stringBuffer.writeln('$defaultBranchKey: $defaultBranch');
    stringBuffer.writeln('$autoApprovalAccountsKey:');
    for (var account in autoApprovalAccounts) {
      stringBuffer.writeln('  - $account');
    }
    stringBuffer.writeln('$approvingReviewsKey: $approvingReviews');
    stringBuffer.writeln('$approvalGroupKey: $approvalGroup');
    stringBuffer.writeln('$runCiKey: $runCi');
    stringBuffer.writeln('$supportNoReviewRevertKey: $supportNoReviewReverts');
    stringBuffer.writeln('$requiredCheckRunsOnRevertKey:');
    for (var checkrun in requiredCheckRunsOnRevert) {
      stringBuffer.writeln('  - $checkrun');
    }
    stringBuffer.writeln('$baseCommitAllowedDaysKey: $baseCommitAllowedDays');
    return stringBuffer.toString();
  }

  static RepositoryConfiguration fromYaml(String yaml) {
    final dynamic yamlDoc = loadYaml(yaml);

    final autoApprovalAccounts = <String>{};
    final yamlAutoApprovalAccounts =
        yamlDoc[autoApprovalAccountsKey] as YamlList?;
    if (yamlAutoApprovalAccounts != null) {
      for (var element in yamlAutoApprovalAccounts.nodes) {
        autoApprovalAccounts.add(element.value as String);
      }
    }

    if (yamlDoc[approvalGroupKey] == null) {
      throw ConfigurationException('The approval group is a required field.');
    }

    final requiredCheckRunsOnRevert = <String>{};
    final yamlRequiredCheckRuns =
        yamlDoc[requiredCheckRunsOnRevertKey] as YamlList?;
    if (yamlRequiredCheckRuns != null) {
      for (var element in yamlRequiredCheckRuns.nodes) {
        requiredCheckRunsOnRevert.add(element.value as String);
      }
    }

    return RepositoryConfiguration(
      allowConfigOverride: yamlDoc[allowConfigOverrideKey] as bool?,
      defaultBranch: yamlDoc[defaultBranchKey] as String?,
      autoApprovalAccounts: autoApprovalAccounts,
      approvingReviews: yamlDoc[approvingReviewsKey] as int?,
      approvalGroup: yamlDoc[approvalGroupKey] as String?,
      runCi: yamlDoc[runCiKey] as bool?,
      supportNoReviewReverts: yamlDoc[supportNoReviewRevertKey] as bool?,
      requiredCheckRunsOnRevert: requiredCheckRunsOnRevert,
      baseCommitAllowedDays: yamlDoc[baseCommitAllowedDaysKey] as int?,
    );
  }
}
