// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/exception/configuration_exception.dart';
import 'package:github/github.dart';
import 'package:yaml/yaml.dart';

class RepositoryConfigurationBuilder {
  String? _defaultBranch;
  RepositorySlug? _issuesRepository;
  List<String>? _autoApprovalAccounts = [];
  int? _approvingReviews = 2;
  bool? _runCi = true;
  bool? _supportNoReviewReverts = true;
  List<String>? _requiredCheckRuns = [];

  set defaultBranch(String value) => _defaultBranch = value;

  set issuesRepository(RepositorySlug value) => _issuesRepository = value;

  set autoApprovalAccounts(List<String>? value) {
    if (value != null && value.isNotEmpty) {
      _autoApprovalAccounts = value;
    }
  }

  set approvingReviews(int? value) {
    if (value != null) {
      _approvingReviews = value;
    }
  }

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

  set requiredCheckRuns(List<String>? value) {
    if (value != null && value.isNotEmpty) {
      _requiredCheckRuns = value;
    }
  }
}

class RepositoryConfiguration {
  // Autosubmit configuration keys
  static const String DEFAULT_BRANCH_KEY = 'default_branch';
  static const String ISSUES_REPOSITORY_KEY = 'issues_repository';
  static const String REPO_OWNER_KEY = 'owner';
  static const String REPO_NAME_KEY = 'repo';
  static const String AUTO_APPROVAL_ACCOUNTS_KEY = 'auto_approval_accounts';
  static const String APPROVING_REVIEWS_KEY = 'approving_reviews';
  static const String RUN_CI_KEY = 'run_ci';
  static const String SUPPORT_NO_REVIEW_REVERT_KEY = 'support_no_review_revert';
  static const String REQUIRED_CHECK_RUNS_KEY = 'required_checkruns';

  RepositoryConfiguration(RepositoryConfigurationBuilder builder)
      : _defaultBranch = builder._defaultBranch!,
        _issuesRepository = builder._issuesRepository!,
        _autoApprovalAccounts = builder._autoApprovalAccounts!,
        _approvingReviews = builder._approvingReviews!,
        _runCi = builder._runCi!,
        _supportNoReviewReverts = builder._supportNoReviewReverts!,
        _requiredCheckRuns = builder._requiredCheckRuns!;

  final String _defaultBranch;
  final RepositorySlug _issuesRepository;
  final List<String> _autoApprovalAccounts;
  final int _approvingReviews;
  final bool _runCi;
  final bool _supportNoReviewReverts;
  final List<String> _requiredCheckRuns;

  String get defaultBranch => _defaultBranch;

  RepositorySlug get issuesRepository => _issuesRepository;

  List<String> get autoApprovalAccounts => _autoApprovalAccounts;

  int get approvingReviews => _approvingReviews;

  bool get runCi => _runCi;

  bool get supportNoReviewReverts => _supportNoReviewReverts;

  List<String> get requiredCheckRuns => _requiredCheckRuns;

  @override
  String toString() {
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln('$DEFAULT_BRANCH_KEY: $_defaultBranch');
    stringBuffer.writeln('$ISSUES_REPOSITORY_KEY:');
    stringBuffer.writeln('  $REPO_OWNER_KEY: ${_issuesRepository.owner}');
    stringBuffer.writeln('  $REPO_NAME_KEY: ${_issuesRepository.name}');
    stringBuffer.writeln('$AUTO_APPROVAL_ACCOUNTS_KEY:');
    for (String account in _autoApprovalAccounts) {
      stringBuffer.writeln('  - $account');
    }
    stringBuffer.writeln('$APPROVING_REVIEWS_KEY: $_approvingReviews');
    stringBuffer.writeln('$RUN_CI_KEY: $_runCi');
    stringBuffer.writeln('$SUPPORT_NO_REVIEW_REVERT_KEY: $_supportNoReviewReverts');
    stringBuffer.writeln('$REQUIRED_CHECK_RUNS_KEY:');
    for (String checkrun in _requiredCheckRuns) {
      stringBuffer.writeln('  - $checkrun');
    }
    return stringBuffer.toString();
  }

  static RepositoryConfiguration fromYaml(String fileContents) {
    final RepositoryConfigurationBuilder builder = RepositoryConfigurationBuilder();

    final dynamic yamlDoc = loadYaml(fileContents);

    // Default branch is required.
    if (yamlDoc[DEFAULT_BRANCH_KEY] != null) {
      builder.defaultBranch = yamlDoc[DEFAULT_BRANCH_KEY];
    } else {
      throw ConfigurationException('The default branch is a required field.');
    }

    // Issues RepositorySlug is required.
    if (yamlDoc[ISSUES_REPOSITORY_KEY] != null &&
        yamlDoc[ISSUES_REPOSITORY_KEY][REPO_OWNER_KEY] != null &&
        yamlDoc[ISSUES_REPOSITORY_KEY][REPO_NAME_KEY] != null) {
      builder.issuesRepository = RepositorySlug(
        yamlDoc[ISSUES_REPOSITORY_KEY][REPO_OWNER_KEY],
        yamlDoc[ISSUES_REPOSITORY_KEY][REPO_NAME_KEY],
      );
    } else {
      throw ConfigurationException('The Issues Repository Slug is a required field.');
    }

    final List<String> autoApprovalAccounts = [];
    final YamlList? yamlAutoApprovalAccounts = yamlDoc[AUTO_APPROVAL_ACCOUNTS_KEY];
    if (yamlAutoApprovalAccounts != null) {
      for (var element in yamlAutoApprovalAccounts) {
        autoApprovalAccounts.add(element as String);
      }
    }
    builder.autoApprovalAccounts = autoApprovalAccounts;

    builder.approvingReviews = yamlDoc[APPROVING_REVIEWS_KEY];

    builder.runCi = yamlDoc[RUN_CI_KEY];

    builder.supportNoReviewReverts = yamlDoc[SUPPORT_NO_REVIEW_REVERT_KEY];

    final List<String> requiredCheckRuns = [];
    final YamlList? yamlRequiredCheckRuns = yamlDoc[REQUIRED_CHECK_RUNS_KEY];
    if (yamlRequiredCheckRuns != null) {
      for (var element in yamlRequiredCheckRuns) {
        requiredCheckRuns.add(element as String);
      }
    }
    builder.requiredCheckRuns = requiredCheckRuns;

    return RepositoryConfiguration(builder);
  }
}
