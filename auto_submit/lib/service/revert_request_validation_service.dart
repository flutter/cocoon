// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/action/git_cli_revert_method.dart';
import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/requests/github_pull_request_event.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/validations/validation_filter.dart';
import 'package:github/github.dart' as github;
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:auto_submit/action/revert_method.dart';
import 'process_method.dart';

enum RevertProcessMethod { revert, revertOf, none }

class RevertRequestValidationService extends ValidationService {
  RevertRequestValidationService(Config config, {RetryOptions? retryOptions, RevertMethod? revertMethod})
      : revertMethod = revertMethod ?? GitCliRevertMethod(),
        super(config, retryOptions: retryOptions) {
    /// Validates a PR marked with the reverts label.
    approverService = ApproverService(config);
  }

  ApproverService? approverService;
  @visibleForTesting
  RevertMethod? revertMethod;
  @visibleForTesting
  ValidationFilter? validationFilter;

  /// TODO run the actual request from here and remove the shouldProcess call.
  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(GithubPullRequestEvent githubPullRequestEvent, String ackId, PubSub pubsub) async {
    // Make sure the pull request still contains the labels.
    final github.PullRequest messagePullRequest = githubPullRequestEvent.pullRequest!;
    final (currentPullRequest, labelNames) = await getPrWithLabels(messagePullRequest);
    final RevertProcessMethod revertProcessMethod = await shouldProcess(currentPullRequest, labelNames);

    final GithubPullRequestEvent updatedGithubPullRequestEvent = GithubPullRequestEvent(
      pullRequest: currentPullRequest,
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
          githubPullRequestEvent: updatedGithubPullRequestEvent,
          ackId: ackId,
          pubsub: pubsub,
        );
        break;
      // Do not process.
      case RevertProcessMethod.none:
        log.info('Should not process ${messagePullRequest.toJson()}, and ack the message.');
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

  /// Determine if we should process the incoming pull request webhook event.
  Future<RevertProcessMethod> shouldProcess(github.PullRequest pullRequest, List<String> labelNames) async {
    // This is the initial revert request state.
    if (pullRequest.state == 'closed' && labelNames.contains(Config.kRevertLabel) && pullRequest.mergedAt != null) {
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
    final github.PullRequest messagePullRequest = githubPullRequestEvent.pullRequest!;
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    final String sender = githubPullRequestEvent.sender!.login!;

    if (!isWithinTimeLimit(messagePullRequest)) {
      final String message = '''Time to revert pull request ${slug.fullName}/${messagePullRequest.number} has elapsed.
          You need to open the revert manually and process as a regular pull request.''';
      log.info(message);
      await githubService.createComment(slug, messagePullRequest.number!, message);
      await githubService.removeLabel(slug, messagePullRequest.number!, Config.kRevertLabel);
      log.info('Should not process ${messagePullRequest.toJson()}, and ack the message.');
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
      return;
    }

    // Attempt to create the new revert pull request.
    try {
      // This is the autosubmit query result pull request from graphql.
      final github.PullRequest pullRequest =
          await revertMethod!.createRevert(config, sender, messagePullRequest) as github.PullRequest;
      log.info('Created revert pull request ${slug.fullName}/${pullRequest.number}.');
      // This will come through this service again for processing.
      await githubService.addLabels(slug, pullRequest.number!, [Config.kRevertOfLabel]);
      log.info('Assigning new revert issue to $sender');
      await githubService.addAssignee(slug, pullRequest.number!, [sender]);
      // TODO (ricardoamador) create a better solution than this to stop processing
      // the revert requests. Maybe change the label after the revert has occurred.
      // For some reason we get duplicate events even though we ack the message.
      await githubService.removeLabel(slug, messagePullRequest.number!, Config.kRevertLabel);
      // Notify the discord tree channel that the revert issue has been created
      // and will be processed.
    } catch (e) {
      final String message = 'Unable to create the revert pull request due to ${e.toString()}';
      log.severe(message);
      await githubService.createComment(slug, messagePullRequest.number!, message);
      await githubService.removeLabel(slug, messagePullRequest.number!, Config.kRevertLabel);
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
    final github.PullRequest messagePullRequest = githubPullRequestEvent.pullRequest!;
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    final int prNumber = messagePullRequest.number!;

    // Check to make sure the repository allows review-less revert pull requests
    // so that we can reassign if needed otherwise autoapprove the pull request.
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);
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

    final Set<Validation> validations = validationFilter!.getValidations();

    final Map<String, ValidationResult> validationsMap = <String, ValidationResult>{};

    /// Runs all the validation defined in the service.
    /// If the runCi flag is false then we need a way to not run the ciSuccessful validation.
    for (Validation validation in validations) {
      log.info('${slug.fullName}/$prNumber running validation ${validation.name}');
      validationsMap[validation.name] = await validation.validate(
        result,
        // this needs to be the newly opened pull request.
        messagePullRequest,
      );
    }

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    for (MapEntry<String, ValidationResult> result in validationsMap.entries) {
      if (!result.value.result && result.value.action == Action.REMOVE_LABEL) {
        final String commmentMessage = result.value.message.isEmpty ? 'Validations Fail.' : result.value.message;
        final String message = 'auto label is removed for ${slug.fullName}/$prNumber, due to $commmentMessage';
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
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
      return;
    }

    // If PR has some failures to ignore temporarily do nothing and continue.
    for (MapEntry<String, ValidationResult> result in validationsMap.entries) {
      if (!result.value.result && result.value.action == Action.IGNORE_TEMPORARILY) {
        log.info(
          'Temporarily ignoring processing of ${slug.fullName}/$prNumber due to ${result.key} failing validation.',
        );
        return;
      }
    }

    // If we got to this point it means we are ready to submit the PR.
    final MergeResult processed = await processMerge(
      config: config,
      messagePullRequest: messagePullRequest,
    );

    if (!processed.result) {
      final String message = 'auto label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
      await githubService.removeLabel(slug, prNumber, Config.kRevertOfLabel);
      await githubService.createComment(slug, prNumber, message);
      log.info(message);
    } else {
      log.info('Revert merged successfully, deleting branch ${messagePullRequest.head!.ref!}');
      await githubService.deleteBranch(slug, messagePullRequest.head!.ref!);
      log.info('Pull Request ${slug.fullName}/$prNumber was merged successfully!');
      log.info('Attempting to insert a pull request record into the database for $prNumber');
      await insertPullRequestRecord(
        config: config,
        pullRequest: messagePullRequest,
        pullRequestType: PullRequestChangeType.revert,
      );
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
  }
}
