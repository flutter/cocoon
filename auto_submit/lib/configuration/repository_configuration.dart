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
  static const String stalePrProtectionInDaysForBaseRefsKey =
      'stale_pr_protection_in_days_for_base_refs';

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
    Map<String, int>? stalePrProtectionInDaysForBaseRefs,
  }) : allowConfigOverride = allowConfigOverride ?? false,
       defaultBranch = defaultBranch ?? defaultBranchStr,
       autoApprovalAccounts = autoApprovalAccounts ?? <String>{},
       approvingReviews = approvingReviews ?? 2,
       approvalGroup = approvalGroup ?? 'flutter-hackers',
       runCi = runCi ?? true,
       supportNoReviewReverts = supportNoReviewReverts ?? true,
       requiredCheckRunsOnRevert = requiredCheckRunsOnRevert ?? <String>{},
       stalePrProtectionInDaysForBaseRefs =
           stalePrProtectionInDaysForBaseRefs ?? <String, int>{};

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

  /// A map of [slug]/[branch] as a key and number of days to validate PR base
  /// date is not older than on that [slug]/[branch].
  Map<String, int> stalePrProtectionInDaysForBaseRefs;

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
    if (stalePrProtectionInDaysForBaseRefs.isNotEmpty) {
      stringBuffer.writeln('$stalePrProtectionInDaysForBaseRefsKey:');
      for (final MapEntry(key: branch, value: days)
          in stalePrProtectionInDaysForBaseRefs.entries) {
        stringBuffer.writeln('  $branch: $days');
      }
    }
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

    final stalePrProtectionInDaysForBaseRefs = <String, int>{};
    final yamlstalePrProtectionInDaysForBaseRefs =
        yamlDoc[stalePrProtectionInDaysForBaseRefsKey] as YamlMap?;
    if (yamlstalePrProtectionInDaysForBaseRefs != null) {
      for (var entry in yamlstalePrProtectionInDaysForBaseRefs.entries) {
        if (entry.value is! int) {
          throw ConfigurationException(
            'The value for ${entry.key} must be an integer.',
          );
        }
        if (entry.value as int <= 0) {
          throw ConfigurationException(
            'The value for ${entry.key} must be greater than zero.',
          );
        }

        stalePrProtectionInDaysForBaseRefs[entry.key as String] =
            entry.value as int;
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
      stalePrProtectionInDaysForBaseRefs: stalePrProtectionInDaysForBaseRefs,
    );
  }
}
