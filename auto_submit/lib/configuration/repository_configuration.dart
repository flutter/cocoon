// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/exception/configuration_exception.dart';
import 'package:yaml/yaml.dart';

/// RepositoryConfigurationBuilder is used to build the RepositoryConfiguration
/// object. It allows the default values or missing values to be configured for
/// the configuration before sending it on for use.
class RepositoryConfigurationBuilder {
  bool? _allowConfigOverride = false;
  String? _defaultBranch = '';
  Set<String>? _autoApprovalAccounts = {};
  int? _approvingReviews = 2;
  String? _approvalGroup = '';
  bool? _runCi = true;
  bool? _supportNoReviewReverts = true;
  Set<String>? _requiredCheckRunsOnRevert = {};

  set allowConfigOverride(bool value) => _allowConfigOverride = value;

  set defaultBranch(String value) => _defaultBranch = value;

  set autoApprovalAccounts(Set<String>? value) {
    if (value != null && value.isNotEmpty) {
      _autoApprovalAccounts = value;
    }
  }

  set approvingReviews(int? value) {
    if (value != null) {
      _approvingReviews = value;
    }
  }

  set approvalGroup(String? value) => _approvalGroup = value;

  set runCi(bool? value) {
    if (value != null) {
      _runCi = value;
    }
  }

  set supportNoReviewReverts(bool? value) {
    if (value != null) {
      _supportNoReviewReverts = value;
    }
  }

  set requiredCheckRunsOnRevert(Set<String>? value) {
    if (value != null && value.isNotEmpty) {
      _requiredCheckRunsOnRevert = value;
    }
  }
}

/// The RepositoryConfiguration stores the pertinent information that autosubmit
/// will need when submiting and validating pull requests for a particular
/// repository.
class RepositoryConfiguration {
  // Autosubmit configuration keys as found in the yaml configuraiton file.
  static const String ALLOW_CONFIG_OVERRIDE_KEY = 'allow_config_override';
  static const String DEFAULT_BRANCH_KEY = 'default_branch';
  static const String AUTO_APPROVAL_ACCOUNTS_KEY = 'auto_approval_accounts';
  static const String APPROVING_REVIEWS_KEY = 'approving_reviews';
  static const String APPROVAL_GROUP_KEY = 'approval_group';
  static const String RUN_CI_KEY = 'run_ci';
  static const String SUPPORT_NO_REVIEW_REVERT_KEY = 'support_no_review_revert';
  static const String REQUIRED_CHECK_RUNS_KEY = 'required_checkruns_on_revert';

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
  /// of the approval group they will need (approvingReviews - 1) number of
  /// reviews in order to merge the pull request, if they are not part of the
  /// approval group the will need approvingReviews number of reviews.
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
    stringBuffer.writeln('$ALLOW_CONFIG_OVERRIDE_KEY: $allowConfigOverride');
    stringBuffer.writeln('$DEFAULT_BRANCH_KEY: $defaultBranch');
    stringBuffer.writeln('$AUTO_APPROVAL_ACCOUNTS_KEY:');
    for (String account in autoApprovalAccounts!) {
      stringBuffer.writeln('  - $account');
    }
    stringBuffer.writeln('$APPROVING_REVIEWS_KEY: $approvingReviews');
    stringBuffer.writeln('$APPROVAL_GROUP_KEY: $approvalGroup');
    stringBuffer.writeln('$RUN_CI_KEY: $runCi');
    stringBuffer.writeln('$SUPPORT_NO_REVIEW_REVERT_KEY: $supportNoReviewReverts');
    stringBuffer.writeln('$REQUIRED_CHECK_RUNS_KEY:');
    for (String checkrun in requiredCheckRunsOnRevert!) {
      stringBuffer.writeln('  - $checkrun');
    }
    return stringBuffer.toString();
  }

  static RepositoryConfiguration fromYaml(String yaml) {
    final RepositoryConfigurationBuilder builder = RepositoryConfigurationBuilder();

    final dynamic yamlDoc = loadYaml(yaml);

    if (yamlDoc[ALLOW_CONFIG_OVERRIDE_KEY] != null) {
      builder.allowConfigOverride = yamlDoc[ALLOW_CONFIG_OVERRIDE_KEY];
    }

    // Default branch is required.
    if (yamlDoc[DEFAULT_BRANCH_KEY] != null) {
      builder.defaultBranch = yamlDoc[DEFAULT_BRANCH_KEY];
    }

    final Set<String> autoApprovalAccounts = {};
    final YamlList? yamlAutoApprovalAccounts = yamlDoc[AUTO_APPROVAL_ACCOUNTS_KEY];
    if (yamlAutoApprovalAccounts != null) {
      for (var element in yamlAutoApprovalAccounts) {
        autoApprovalAccounts.add(element as String);
      }
    }
    builder.autoApprovalAccounts = autoApprovalAccounts;

    builder.approvingReviews = yamlDoc[APPROVING_REVIEWS_KEY];

    if (yamlDoc[APPROVAL_GROUP_KEY] != null) {
      builder.approvalGroup = yamlDoc[APPROVAL_GROUP_KEY];
    } else {
      throw ConfigurationException('The approval group is a required field.');
    }

    builder.runCi = yamlDoc[RUN_CI_KEY];

    builder.supportNoReviewReverts = yamlDoc[SUPPORT_NO_REVIEW_REVERT_KEY];

    final Set<String> requiredCheckRunsOnRevert = {};
    final YamlList? yamlRequiredCheckRuns = yamlDoc[REQUIRED_CHECK_RUNS_KEY];
    if (yamlRequiredCheckRuns != null) {
      for (var element in yamlRequiredCheckRuns) {
        requiredCheckRunsOnRevert.add(element as String);
      }
    }
    builder.requiredCheckRunsOnRevert = requiredCheckRunsOnRevert;

    return RepositoryConfiguration(
      allowConfigOverride: builder._allowConfigOverride,
      defaultBranch: builder._defaultBranch,
      autoApprovalAccounts: builder._autoApprovalAccounts,
      approvingReviews: builder._approvingReviews,
      approvalGroup: builder._approvalGroup,
      runCi: builder._runCi,
      supportNoReviewReverts: builder._supportNoReviewReverts,
      requiredCheckRunsOnRevert: builder._requiredCheckRunsOnRevert,
    );
  }
}
