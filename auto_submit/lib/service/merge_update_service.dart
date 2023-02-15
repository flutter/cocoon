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

    final RepositorySlug slug = RepositorySlug.full(mergeCommentMessage.repository!.fullName);
    final GithubService githubService = await config.createGithubService(slug);

    // get the list of comments on the pull request issue.

    // Need to get the Reposlug from the issue
    if (mergeCommentMessage.comment!.authorAssociation != 'MEMBER' && mergeCommentMessage.comment!.authorAssociation != 'OWNER') {
      const String message = 'You must be a MEMBER or OWNER author to request a merge update.';
      log.info(message);
      // Add a message to the issue.
      await githubService.createComment(slug, mergeCommentMessage.issue!.number, message);
    } else {
      final String defaultBranch = mergeCommentMessage.repository!.defaultBranch;
      final GitReference gitReference = await githubService.getReference(slug, 'heads/$defaultBranch');
      final bool status = await githubService.updateBranch(slug, mergeCommentMessage.issue!.number, gitReference.object!.sha!);
      String message;
      if (status) {
        message = 'Successfully merged ${gitReference.object!.sha!} into this pull request ${mergeCommentMessage.issue!.number}';
        log.info(message);
      } else {
        message = 'Unable to merge ${gitReference.object!.sha!} into this pull request ${mergeCommentMessage.issue!.number}';
        log.severe(message);
      }
      await githubService.createComment(slug, mergeCommentMessage.issue!.number, message);
    }
    await pubsub.acknowledge('auto-submit-comment-sub', ackId);
  }
}
