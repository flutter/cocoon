// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart' as github;

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
  Future<Set<String>> getAutoApprovalAccounts(github.RepositorySlug slug) async {
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);
    final Set<String> approvalAccounts = repositoryConfiguration.autoApprovalAccounts;
    return approvalAccounts;
  }

  Future<void> autoApproval(github.PullRequest pullRequest) async {
    final String? author = pullRequest.user!.login;
    final int prNumber = pullRequest.number!;
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final Set<String> approvalAccounts =
        await getAutoApprovalAccounts(github.RepositorySlug.full(pullRequest.base!.repo!.fullName));

    log.info('Determining auto approval of $author on ${slug.fullName}/$prNumber.');

    // If there are auto_approvers let them approve the pull request.
    if (!approvalAccounts.contains(author)) {
      log.info('Auto-review ignored for $author on ${slug.fullName}/$prNumber.');
    } else {
      log.info('Auto approval detected on ${slug.fullName}/$prNumber.');
      await _approve(pullRequest, author);
    }
  }

  /// Auto approves a pull request when the revert label is present.
  Future<void> revertApproval(github.PullRequest pullRequest) async {
    final String? author = pullRequest.user!.login;
    // Use the QueryResult for this field
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    log.info('Attempting to approve revert request ${slug.fullName}/${pullRequest.number} by author $author.');

    final List<String> labelNames = (pullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    log.info('Found labels $labelNames on this pull request ${slug.fullName}/${pullRequest.number}.');

    final Set<String> approvalAccounts =
        await getAutoApprovalAccounts(github.RepositorySlug.full(pullRequest.base!.repo!.fullName));

    final GithubService githubService = await config.createGithubService(slug);

    if (labelNames.contains(Config.kRevertLabel) &&
        (approvalAccounts.contains(author) ||
            await githubService.isTeamMember(repositoryConfiguration.approvalGroup, author!, slug.owner))) {
      log.info(
        'Revert label and author has been validated. Attempting to approve the pull request ${slug.fullName}/${pullRequest.number} by $author',
      );
      await _approve(pullRequest, author);
    } else {
      log.info('Auto-review ignored for $author on ${slug.fullName}/${pullRequest.number}');
    }
  }

  Future<void> _approve(github.PullRequest pullRequest, String? author) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final github.GitHub botClient = await config.createFlutterGitHubBotClient(slug);

    final Stream<github.PullRequestReview> reviews = botClient.pullRequests.listReviews(slug, pullRequest.number!);
    // TODO(ricardoamador) this will need to be refactored to make this code more general and
    // not applicable to only flutter.
    await for (github.PullRequestReview review in reviews) {
      if (review.user.login == 'fluttergithubbot' && review.state == 'APPROVED') {
        // Already approved.
        return;
      }
    }

    final github.CreatePullRequestReview review =
        github.CreatePullRequestReview(slug.owner, slug.name, pullRequest.number!, 'APPROVE');
    await botClient.pullRequests.createReview(slug, review);
    log.info('Review for ${slug.fullName}/${pullRequest.number} complete');
  }
}
