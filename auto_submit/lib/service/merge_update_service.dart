// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/merge_comment_message.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';

import '../request_handling/pubsub.dart';

class MergeUpdateService {
  final Config config;

  MergeUpdateService(this.config);

  /// Updates a pull request by merging the HEAD into the current PR branch.
  Future<void> processMessage(
    MergeCommentMessage mergeCommentMessage,
    String ackId,
    PubSub pubsub,
  ) async {
    log.info('Processing $ackId');
    final RepositorySlug slug = RepositorySlug.full(mergeCommentMessage.repository!.fullName);
    final GithubService githubService = await config.createGithubService(slug);

    // Make sure the pull request is still open before we do anything else.
    final PullRequest pullRequest = await githubService.getPullRequest(
      slug,
      mergeCommentMessage.issue!.number,
    );

    if (pullRequest.state != 'open') {
      log.info('Ignoring closed pull request as it is not open.');
      await pubsub.acknowledge(
        Config.pubSubCommentSubscription,
        ackId,
      );
      return;
    } else {
      log.info('Pull request is still open.');
    }

    if (pullRequest.mergeable != null && !pullRequest.mergeable!) {
      const String message = 'Ignoring pull request merge request as it is not in a mergeable state.';
      log.info(message);
      await githubService.createComment(
        slug,
        mergeCommentMessage.issue!.number,
        message,
      );
      await pubsub.acknowledge(
        Config.pubSubCommentSubscription,
        ackId,
      );

      return;
    } else {
      log.info('Pull request is in a mergeable state.');
    }

    // Get the updated IssueComment.
    final IssueComment? issueComment = await getIssueComment(
      githubService,
      slug,
      mergeCommentMessage.comment!.id!,
    );
    if (issueComment == null) {
      log.info('Message could no longer be found in issue.');
      await pubsub.acknowledge(
        Config.pubSubCommentSubscription,
        ackId,
      );
      return;
    } else {
      log.info('Merge request is still valid.');
    }

    // Make sure the comment still requests the merge update. Last chance to unrequest merge.
    if (issueComment.body == null || !Config.regExpMergeMethod.hasMatch(issueComment.body!)) {
      const String message = 'Merge request not found in comment, ignoring.';
      log.info(message);
      await pubsub.acknowledge(
        Config.pubSubCommentSubscription,
        ackId,
      );
      return;
    }

    // TODO not sure why we need to do this... Anyone can update their pull requests.
    if (issueComment.authorAssociation == null ||
        !Config.approvedAuthorAssociations.contains(issueComment.authorAssociation!)) {
      const String message = 'You must be a MEMBER or OWNER author to request a merge update.';
      log.info(message);
      // Add a message to the issue.
      await githubService.createComment(
        slug,
        mergeCommentMessage.issue!.number,
        message,
      );
      await pubsub.acknowledge(
        Config.pubSubCommentSubscription,
        ackId,
      );
      return;
    }

    final bool? status = await githubService.autoMergeBranch(pullRequest);

    String message;
    if (status != null) {
      if (status) {
        message = 'Successfully updated pull request';
        log.info(message);
      } else {
        message = 'Unable to update pull request';
        log.severe(message);
      }
    } else {
      message = 'No update needed, branch is not behind head.';
      log.info(message);
    }

    await githubService.createComment(
      slug,
      mergeCommentMessage.issue!.number,
      message,
    );

    await pubsub.acknowledge(Config.pubSubCommentSubscription, ackId);
  }

  Future<IssueComment?> getIssueComment(
    GithubService githubService,
    RepositorySlug slug,
    int commentId,
  ) async {
    IssueComment? issueComment;
    try {
      issueComment = await githubService.getComment(slug, commentId);
    } on NotFound {
      // The comment does not exist, this is not an issue.
      log.info('Comment has been deleted. Ignoring update request.');
    } catch (e) {
      // some other exception that IS an error.
      log.severe('An error has occurred while attempting to get issue comment: $e.');
    }
    return issueComment;
  }
}
