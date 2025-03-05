// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../action/git_cli_revert_method.dart';
import '../action/revert_method.dart';
import '../model/auto_submit_query_result.dart';
import '../model/discord_message.dart';
import '../model/pull_request_data_types.dart';
import '../request_handling/pubsub.dart';
import '../requests/github_pull_request_event.dart';
import '../revert/revert_discord_message.dart';
import '../revert/revert_info_collection.dart';
import '../validations/validation.dart';
import '../validations/validation_filter.dart';
import 'approver_service.dart';
import 'config.dart';
import 'discord_notification.dart';
import 'github_service.dart';
import 'process_method.dart';
import 'validation_service.dart';

enum RevertProcessMethod { revert, revertOf, none }

class RevertRequestValidationService extends ValidationService {
  RevertRequestValidationService(
    Config config, {
    RetryOptions? retryOptions,
    RevertMethod? revertMethod,
  })  : revertMethod = revertMethod ?? GitCliRevertMethod(),
        super(config, retryOptions: retryOptions) {
    /// Validates a PR marked with the reverts label.
    approverService = ApproverService(config);
  }

  ApproverService? approverService;
  @visibleForTesting
  RevertMethod? revertMethod;
  @visibleForTesting
  ValidationFilter? validationFilter;
  DiscordNotification? discordNotification;

  /// TODO run the actual request from here and remove the shouldProcess call.
  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(
    GithubPullRequestEvent githubPullRequestEvent,
    String ackId,
    PubSub pubsub,
  ) async {
    // Make sure the pull request still contains the labels.
    final messagePullRequest = githubPullRequestEvent.pullRequest!;
    final slug = messagePullRequest.base!.repo!.slug();
    final fullPullRequest = await getFullPullRequest(
      slug,
      messagePullRequest.number!,
    );
    final revertProcessMethod = await shouldProcess(fullPullRequest);

    final updatedGithubPullRequestEvent = GithubPullRequestEvent(
      pullRequest: fullPullRequest,
      action: githubPullRequestEvent.action,
      sender: githubPullRequestEvent.sender,
    );

    switch (revertProcessMethod) {
      // Revert is the processing of the closed issue.
      case RevertProcessMethod.revert:
        await processRevertRequest(
          result: await getNewestPullRequestInfo(config, messagePullRequest),
          githubPullRequestEvent: updatedGithubPullRequestEvent,
          ackId: ackId,
          pubsub: pubsub,
        );
        break;
      // Reverts is the processing of the opened revert issue.
      case RevertProcessMethod.revertOf:
        await processRevertOfRequest(
          result: await getNewestPullRequestInfo(config, messagePullRequest),
          githubPullRequestEvent: githubPullRequestEvent,
          ackId: ackId,
          pubsub: pubsub,
        );
        break;
      // Do not process.
      case RevertProcessMethod.none:
        log.info(
          'Should not process ${messagePullRequest.toJson()}, and ack the message.',
        );
        await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
        break;
    }
  }

  /// Check whether the original request is within the 24 hour time limit to revert.
  bool isWithinTimeLimit(github.PullRequest pullRequest) {
    if (pullRequest.mergedAt == null) {
      // This pull request has never been merged.
      return false;
    }
    return DateTime.now().difference(pullRequest.mergedAt!).inHours <= 24;
  }

  final RegExp regExp = RegExp(
    r'\s*[R|r]eason\s+for\s+[R|r]evert:?\s+([\S|\s]{1,400})',
    multiLine: true,
  );

  /// Determine whether or not the original pull request to be reverted has a reason
  /// why the issue is being reverted.
  Future<String?> getReasonForRevert(
    GithubService githubService,
    github.RepositorySlug slug,
    int issueNumber,
  ) async {
    final pullRequestComments = await githubService.getIssueComments(
      slug,
      issueNumber,
    );
    log.info(
      'Found ${pullRequestComments.length} comments for issue ${slug.fullName}/$issueNumber',
    );
    for (var prComment in pullRequestComments) {
      final commentBody = prComment.body;
      log.info(
        'Processing comment on ${slug.fullName}/$issueNumber: $commentBody',
      );
      if (commentBody != null && regExp.hasMatch(commentBody)) {
        final matches = regExp.allMatches(commentBody);
        final Match m = matches.first;
        return m.group(1);
      }
    }
    return null;
  }

  /// Determine if we should process the incoming pull request webhook event.
  Future<RevertProcessMethod> shouldProcess(
    github.PullRequest pullRequest,
  ) async {
    final labelNames = pullRequest.labelNames;
    // This is the initial revert request state.
    if (pullRequest.state == 'closed' &&
        labelNames.contains(Config.kRevertLabel) &&
        pullRequest.mergedAt != null) {
      return RevertProcessMethod.revert;
    } else if (pullRequest.state == 'open' &&
        labelNames.contains(Config.kRevertOfLabel) &&
        pullRequest.user!.login == 'auto-submit[bot]') {
      // This is the path where we check validations
      return RevertProcessMethod.revertOf;
    }
    return RevertProcessMethod.none;
  }

  // pullRequest.state == 'closed' && labelNames.contains('revert')
  // TODO need a way to stop processing this.
  Future<void> processRevertRequest({
    required QueryResult result,
    required GithubPullRequestEvent githubPullRequestEvent,
    required String ackId,
    required PubSub pubsub,
  }) async {
    final messagePullRequest = githubPullRequestEvent.pullRequest!;
    final slug = messagePullRequest.base!.repo!.slug();
    final githubService = await config.createGithubService(slug);
    final sender = githubPullRequestEvent.sender!.login!;

    if (!isWithinTimeLimit(messagePullRequest)) {
      final message =
          '''Time to revert pull request ${slug.fullName}/${messagePullRequest.number} has elapsed.
          You need to open the revert manually and process as a regular pull request.''';
      log.info(message);
      await githubService.createComment(
        slug,
        messagePullRequest.number!,
        message,
      );
      await githubService.removeLabel(
        slug,
        messagePullRequest.number!,
        Config.kRevertLabel,
      );
      log.info(
        'Should not process ${messagePullRequest.toJson()}, and ack the message.',
      );
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
      return;
    }

    final revertReason = await getReasonForRevert(
      githubService,
      slug,
      messagePullRequest.number!,
    );
    if (revertReason == null) {
      final message =
          '''A reason for requesting a revert of ${slug.fullName}/${messagePullRequest.number} could
      not be found or the reason was not properly formatted. Begin a comment with **'Reason for revert:'** to tell the bot why
      this issue is being reverted.''';
      log.info(message);
      await githubService.createComment(
        slug,
        messagePullRequest.number!,
        message,
      );
      await githubService.removeLabel(
        slug,
        messagePullRequest.number!,
        Config.kRevertLabel,
      );
      log.info(
        'Should not process ${messagePullRequest.toJson()}, and ack the message.',
      );
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
      return;
    }

    // Attempt to create the new revert pull request.
    try {
      // This is the autosubmit query result pull request from graphql.
      final pullRequest = await revertMethod!.createRevert(
        config,
        sender,
        revertReason,
        messagePullRequest,
      ) as github.PullRequest;
      log.info(
        'Created revert pull request ${slug.fullName}/${pullRequest.number}.',
      );
      // This will come through this service again for processing.
      await githubService.addLabels(slug, pullRequest.number!, [
        Config.kRevertOfLabel,
      ]);
      log.info('Assigning new revert issue to $sender');
      await githubService.addAssignee(slug, pullRequest.number!, [sender]);
      // TODO (ricardoamador) create a better solution than this to stop processing
      // the revert requests. Maybe change the label after the revert has occurred.
      // For some reason we get duplicate events even though we ack the message.
      await githubService.removeLabel(
        slug,
        messagePullRequest.number!,
        Config.kRevertLabel,
      );
      // Notify the discord tree channel that the revert issue has been created
      // and will be processed.
    } catch (e) {
      final message =
          'Unable to create the revert pull request due to ${e.toString()}';
      log.severe(message);
      await githubService.createComment(
        slug,
        messagePullRequest.number!,
        message,
      );
      await githubService.removeLabel(
        slug,
        messagePullRequest.number!,
        Config.kRevertLabel,
      );
    } finally {
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
    }
  }

  /// Processes a PullRequest running several validations to decide whether to
  /// land the commit or remove the label.
  // pullRequest.state == 'open' && labelNames.contains('revert of')
  Future<void> processRevertOfRequest({
    required QueryResult result,
    required GithubPullRequestEvent githubPullRequestEvent,
    required String ackId,
    required PubSub pubsub,
  }) async {
    final pullRequest = githubPullRequestEvent.pullRequest!;
    final slug = pullRequest.base!.repo!.slug();
    final githubService = await config.createGithubService(slug);
    final prNumber = pullRequest.number!;

    // If a pull request is currently in the merge queue do not touch it. Let
    // the merge queue merge it, or kick it out of the merge queue.
    if (pullRequest.isMergeQueueEnabled) {
      if (result.repository!.pullRequest!.isInMergeQueue) {
        log.info(
          '${slug.fullName}/$prNumber is already in the merge queue. Skipping.',
        );
        await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
        return;
      }
    }

    // Check to make sure the repository allows review-less revert pull requests
    // so that we can reassign if needed otherwise autoapprove the pull request.
    final repositoryConfiguration = await config.getRepositoryConfiguration(
      slug,
    );
    if (!repositoryConfiguration.supportNoReviewReverts) {
      await githubService.removeLabel(slug, prNumber, Config.kRevertOfLabel);
      await githubService.createComment(
        slug,
        prNumber,
        'Repository configuration does not support review-less revert pull requests. Please assign at least two reviewers to this pull request.',
      );
      // We do not want to continue processing this issue.
      log.info('Ack the processed message : $ackId.');
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
      return;
    }

    validationFilter ??= ValidationFilter(
      config: config,
      processMethod: ProcessMethod.processRevert,
      repositoryConfiguration: repositoryConfiguration,
    );

    final validations = validationFilter!.getValidations();

    final validationsMap = <String, ValidationResult>{};

    /// Runs all the validation defined in the service.
    /// If the runCi flag is false then we need a way to not run the ciSuccessful validation.
    for (var validation in validations) {
      log.info(
        '${slug.fullName}/$prNumber running validation ${validation.name}',
      );
      validationsMap[validation.name] = await validation.validate(
        result,
        // this needs to be the newly opened pull request.
        pullRequest,
      );
    }

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    var shouldReturn = false;
    for (final MapEntry(key: _, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.REMOVE_LABEL) {
        final commmentMessage =
            value.message.isEmpty ? 'Validations Fail.' : value.message;
        final message =
            'auto label is removed for ${slug.fullName}/$prNumber, due to $commmentMessage';
        await githubService.removeLabel(slug, prNumber, Config.kRevertOfLabel);
        await githubService.createComment(slug, prNumber, message);
        log.info(message);
        shouldReturn = true;
      }
    }

    if (shouldReturn) {
      log.info(
        'The pr ${slug.fullName}/$prNumber with message: $ackId should be acknowledged due to validation failure.',
      );
      log.info(
        'The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.',
      );
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
      return;
    }

    // If PR has some failures to ignore temporarily do nothing and continue.
    for (final MapEntry(:key, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.IGNORE_TEMPORARILY) {
        log.info(
          'Temporarily ignoring processing of ${slug.fullName}/$prNumber due to $key failing validation.',
        );
        return;
      }
    }

    // If we got to this point it means we are ready to submit the PR.
    final processed = await submitPullRequest(
      config: config,
      pullRequest: pullRequest,
    );

    if (!processed.result) {
      final message =
          'auto label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
      await githubService.removeLabel(slug, prNumber, Config.kRevertOfLabel);
      await githubService.createComment(slug, prNumber, message);
      log.info(message);
    } else {
      // Need to add the discord notification here.
      final discordNotification = await discordNotificationClient;
      final Message discordMessage = craftDiscordRevertMessage(pullRequest);
      await discordNotification.notifyDiscordChannelWebhook(
        jsonEncode(discordMessage.toJson()),
      );

      log.info(
        'Pull Request ${slug.fullName}/$prNumber was ${processed.method.pastTenseLabel} successfully!',
      );
      log.info(
        'Attempting to insert a pull request record into the database for $prNumber',
      );
      await insertPullRequestRecord(
        config: config,
        pullRequest: pullRequest,
        pullRequestType: PullRequestChangeType.revert,
      );
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
  }

  Future<DiscordNotification> get discordNotificationClient async {
    discordNotification ??= DiscordNotification(
      targetUri: Uri(
        host: 'discord.com',
        path: await config.getTreeStatusDiscordUrl(),
        scheme: 'https',
      ),
    );
    return discordNotification!;
  }

  RevertDiscordMessage craftDiscordRevertMessage(
    github.PullRequest messagePullRequest,
  ) {
    const githubPrefix = 'https://github.com';
    final revertInfoCollection = RevertInfoCollection();
    final prBody = messagePullRequest.body!;
    // Reverts ${slug.fullName}#$prToRevertNumber'
    final githubFormattedPrLink = revertInfoCollection.extractOriginalPrLink(
      prBody,
    );
    final prLinkSplit = githubFormattedPrLink!.split('#');
    final originalPrNumber = int.parse(prLinkSplit.elementAt(1));
    final slug = messagePullRequest.base!.repo!.slug();
    final revertPrNumber = messagePullRequest.number!;
    final githubFormattedRevertPrLink = '${slug.fullName}#$revertPrNumber';
    // https://github.com/flutter/flutter/pull
    final constructedOriginalPrUrl =
        '$githubPrefix/${slug.fullName}/pull/$originalPrNumber';
    final constructedRevertPrUrl =
        '$githubPrefix/${slug.fullName}/pull/$revertPrNumber';
    final initiatingAuthor = revertInfoCollection.extractInitiatingAuthor(
      prBody,
    );
    final revertReason = revertInfoCollection.extractRevertReason(prBody);
    return RevertDiscordMessage.generateMessage(
      constructedOriginalPrUrl,
      githubFormattedPrLink,
      constructedRevertPrUrl,
      githubFormattedRevertPrLink,
      initiatingAuthor!,
      revertReason!,
    );
  }
}
