// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart' as gh;
import 'package:github/github.dart';

import '../configuration/repository_configuration.dart';
import '../service/config.dart';

/// Function signature for a [ApproverService] provider.
typedef ApproverServiceProvider = ApproverService Function(Config config);

/// Provides github PR approval services.
class ApproverService {
  const ApproverService(this.config);

  final Config config;

  /// Creates and returns a [ApproverService] using [config].
  static ApproverService defaultProvider(Config config) {
    return ApproverService(config);
  }

  /// Get the auto approval accounts from the configuration is any are supplied.
  Future<List<String>> getAutoApprovalAccounts(RepositorySlug slug) async {
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);
    final List<String> approvalAccounts = repositoryConfiguration.autoApprovalAccounts;
    return approvalAccounts;
  }

  Future<void> autoApproval(gh.PullRequest pullRequest) async {
    final String? author = pullRequest.user!.login;
    final List<String> approvalAccounts =
        await getAutoApprovalAccounts(RepositorySlug.full(pullRequest.head!.repo!.fullName));

    log.info('Determine auto approval of $author.');
    log.info('Accounts with auto approval: $approvalAccounts');

    // If there are auto_approvers let them approve the pull request.
    if (!approvalAccounts.contains(author)) {
      log.info('Auto-review ignored for $author');
    } else {
      log.info('Auto approval detected.');
      await _approve(pullRequest, author);
    }
  }

  /// Auto approves a pull request when the revert label is present.
  Future<void> revertApproval(QueryResult queryResult, gh.PullRequest pullRequest) async {
    final Set<String> approvedAuthorAssociations = <String>{'MEMBER', 'OWNER'};

    final String? author = pullRequest.user!.login;
    // Use the QueryResult for this field
    final String? authorAssociation = queryResult.repository!.pullRequest!.authorAssociation;

    log.info('Attempting to approve revert request by author $author, authorAssociation $authorAssociation.');

    final List<String> labelNames =
        (pullRequest.labels as List<gh.IssueLabel>).map<String>((gh.IssueLabel labelMap) => labelMap.name).toList();

    log.info('Found labels $labelNames on this pullRequest.');

    final List<String> approvalAccounts =
        await getAutoApprovalAccounts(RepositorySlug.full(pullRequest.head!.repo!.fullName));

    if (labelNames.contains(Config.kRevertLabel) &&
        (approvalAccounts.contains(author) || approvedAuthorAssociations.contains(authorAssociation))) {
      log.info(
        'Revert label and author has been validated. Attempting to approve the pull request. ${pullRequest.repo} by $author',
      );
      await _approve(pullRequest, author);
    } else {
      log.info('Auto-review ignored for $author');
    }
  }

  Future<void> _approve(gh.PullRequest pullRequest, String? author) async {
    final gh.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final gh.GitHub botClient = await config.createFlutterGitHubBotClient(slug);

    final Stream<gh.PullRequestReview> reviews = botClient.pullRequests.listReviews(slug, pullRequest.number!);
    await for (gh.PullRequestReview review in reviews) {
      if (review.user.login == 'fluttergithubbot' && review.state == 'APPROVED') {
        // Already approved.
        return;
      }
    }

    final gh.CreatePullRequestReview review =
        gh.CreatePullRequestReview(slug.owner, slug.name, pullRequest.number!, 'APPROVE');
    await botClient.pullRequests.createReview(slug, review);
    log.info('Review for $author complete');
  }
}
