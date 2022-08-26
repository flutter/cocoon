// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';

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

  Future<void> autoApproval(PullRequest pullRequest) async {
    final String? author = pullRequest.user!.login;

    if (!config.rollerAccounts.contains(author)) {
      log.info('Auto-review ignored for $author');
    } else {
      await _approve(pullRequest, author);
    }
  }

  /// Auto approves a pull request when the revert label is present.
  Future<void> revertApproval(PullRequest pullRequest) async {
    final Set<String> approvedAuthorAssociations = <String>{'MEMBER', 'OWNER'};

    final String? author = pullRequest.user!.login;
    final String? authorAssociation = pullRequest.authorAssociation;
    final List<String> labelNames =
        (pullRequest.labels as List<IssueLabel>).map<String>((IssueLabel labelMap) => labelMap.name).toList();

    if (labelNames.contains(Config.kRevertLabel) &&
        (config.rollerAccounts.contains(author) || approvedAuthorAssociations.contains(authorAssociation))) {
      await _approve(pullRequest, author);
    } else {
      log.info('Auto-review ignored for $author');
    }
  }

  Future<void> _approve(PullRequest pullRequest, String? author) async {
    final RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GitHub botClient = await config.createFlutterGitHubBotClient(slug);

    Stream<PullRequestReview> reviews = botClient.pullRequests.listReviews(slug, pullRequest.number!);
    await for (PullRequestReview review in reviews) {
      if (review.user.login == 'fluttergithubbot' && review.state == 'APPROVED') {
        // Already approved.
        return;
      }
    }

    final CreatePullRequestReview review =
        CreatePullRequestReview(slug.owner, slug.name, pullRequest.number!, 'APPROVE');
    botClient.pullRequests.createReview(slug, review);
    log.info('Review for $author complete');
  }
}
