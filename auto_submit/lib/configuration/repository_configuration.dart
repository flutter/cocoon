// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:yaml/yaml.dart';

class RepositoryConfiguration {
  const RepositoryConfiguration({
    this.defaultBranch,
    this.issuesRepository,
    this.autoApprovalAccounts,
    this.approvingReviews,
    this.runCi,
    this.supportNoReviewRevert,
    this.requiredCheckRuns,
  });

  final String? defaultBranch;
  final RepositorySlug? issuesRepository;
  final List<String>? autoApprovalAccounts;
  final int? approvingReviews;
  final bool? runCi;
  final bool? supportNoReviewRevert;
  final List<String>? requiredCheckRuns;

  static RepositoryConfiguration fromYaml(String yaml) {
    RepositoryConfiguration repositoryConfiguration;
    final dynamic yamlDoc = loadYaml(yaml);

    final String defBranch = yamlDoc['default_branch'];

    RepositorySlug? issuesRepositorySlug;
    if (yamlDoc['issues_repository'] != null &&
        yamlDoc['issues_repository']['owner'] != null &&
        yamlDoc['issues_repository']['repo'] != null) {
      issuesRepositorySlug = RepositorySlug(
        yamlDoc['issues_repository']['owner'],
        yamlDoc['issues_repository']['repo'],
      );
    }

    final List<String> autoApprovalAccts = [];
    final YamlList? yamlListAccts = yamlDoc['auto_approval_accounts'];
    if (yamlListAccts != null) {
      for (var element in yamlListAccts) {
        autoApprovalAccts.add(element as String);
      }
    }

    final int appReviews = yamlDoc['approving_reviews'] ?? 2;

    final bool rCi = yamlDoc['run_ci'] ?? true;

    final bool supportNoReviewRev = yamlDoc['support_no_review_revert'] ?? true;

    final List<String> reqCheckRuns = [];
    final YamlList? reqdCheckRuns = yamlDoc['required_checkruns'];
    if (reqdCheckRuns != null) {
      for (var element in reqdCheckRuns) {
        reqCheckRuns.add(element as String);
      }
    }

    repositoryConfiguration = RepositoryConfiguration(
      defaultBranch: defBranch,
      issuesRepository: issuesRepositorySlug,
      autoApprovalAccounts: autoApprovalAccts,
      approvingReviews: appReviews,
      runCi: rCi,
      supportNoReviewRevert: supportNoReviewRev,
      requiredCheckRuns: reqCheckRuns,
    );

    return repositoryConfiguration;
  }
}
