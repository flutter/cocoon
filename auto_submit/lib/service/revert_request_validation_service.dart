// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/action/git_cli_revert_method.dart';
import 'package:auto_submit/action/graphql_revert_method.dart';
import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/git/cli_command.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/validations/validation_filter.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

import '../action/revert_method.dart';
import 'process_method.dart';
import 'revert_issue_body_formatter.dart';

class RevertRequestValidationService extends ValidationService {
  RevertRequestValidationService(Config config, {RetryOptions? retryOptions})
      : super(config, retryOptions: retryOptions) {
    /// Validates a PR marked with the reverts label.
    approverService = ApproverService(config);
  }

  ApproverService? approverService;

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
    final (currentPullRequest, labelNames) = await getPrWithLabels(messagePullRequest);
    if (await shouldProcess(currentPullRequest, labelNames)) {
      await processRevertRequest(
        config: config,
        result: await getNewestPullRequestInfo(config, messagePullRequest),
        messagePullRequest: currentPullRequest,
        ackId: ackId,
        pubsub: pubsub,
      );
    } else {
      log.info('Should not process ${messagePullRequest.toJson()}, and ack the message.');
      await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
    }
  }

  Future<bool> shouldProcess(github.PullRequest pullRequest, List<String> labelNames) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    final (currentPullRequest, labelNames) = await getPrWithLabels(pullRequest);

    // This is the initial revert request state.
    if (pullRequest.state == 'closed' && labelNames.contains(Config.kRevertLabel)) {
      // Check the timestamp here as well since we do not want to allow reverts older than
      // 24 hours.
      //
      // There is some nuance here as we still can process and create the revert which
      // will take us to the case above but we need to check again if there are
      // no review reverts supported.
      // if (DateTime.now().difference(currentPullRequest.mergedAt!).inHours > 24) {
      //   final String message =
      //       '''Time to revert pull request ${slug.fullName}/${currentPullRequest.number} has elapsed.
      //      You need to open the revert manually and process as a regular pull request.''';
      //   log.info(message);
      //   await githubService.createComment(slug, currentPullRequest.number!, message);
      //   await githubService.removeLabel(slug, currentPullRequest.number!, Config.kRevertLabel);
      //   return false;
      // }
      return true;
    }
    return false;
  }

  /// Processes a PullRequest running several validations to decide whether to
  /// land the commit or remove the autosubmit label.

  /// The logic for processing a revert request and opening the follow up
  /// review issue in github.
  Future<void> processRevertRequest({
    required Config config,
    required QueryResult result,
    required github.PullRequest messagePullRequest,
    required String ackId,
    required PubSub pubsub,
  }) async {
    // Changed so that the pr coming in has the newest information.

    // Two cases revolve around whether or not we support no-review revert
    // pull requests. If we do not we will simply add the autosubmit label and
    // remove the revert label otherwise process as normal.
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();

    final GraphQLRevertMethod revertMethod = GraphQLRevertMethod();

    // final GitCliRevertMethod gitCliRevertMethod = GitCliRevertMethod();
    final PullRequest? pullRequest;

    try {
      pullRequest = await revertMethod.createRevert(config, messagePullRequest);
    } on Exception {
      log.severe('Unable to create the revert pull request.');
      return;
    }
    // // We only need the number from this.
    log.info('Created revert pull request ${slug.fullName}/${pullRequest!.number}.');
    // We should now have the revert request created.
    final int? prNumber = pullRequest.number;

    final GithubService githubService = await config.createGithubService(slug);

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);
    if (!repositoryConfiguration.supportNoReviewReverts) {
      // Add the autosubmit label and reassigning to the original sender.
      await githubService.addLabels(slug, prNumber!, [Config.kAutosubmitLabel]);
      await githubService.createComment(
          slug, prNumber, 'Repository configuration does not support review-less revert pull requests.');
      await githubService.addReviewersToPullRequest(slug, prNumber, ['originalSender']);
    }

    final ValidationFilter validationFilter = ValidationFilter(
      config: config,
      processMethod: ProcessMethod.processRevert,
      repositoryConfiguration: repositoryConfiguration,
    );

    final Set<Validation> validations = validationFilter.getValidations();

    final Map<String, ValidationResult> validationsMap = <String, ValidationResult>{};

    /// Runs all the validation defined in the service.
    /// If the runCi flag is false then we need a way to not run the ciSuccessful validation.
    for (Validation validation in validations) {
      log.info('${slug.fullName}/$prNumber running validation ${validation.name}');
      final ValidationResult validationResult = await validation.validate(
        result,
        // this needs to be the newly opened pull request.
        messagePullRequest,
      );
      validationsMap[validation.name] = validationResult;
    }

    // There is an issue with running the validations here as they may not be
    // finished in time and if we add a label to the pr earlier it will generate
    // an event and we would have a bad situation. Might be better to add the
    // label and let it pass through again.

    // Approve the pull request.

    // Merge the pull request.

    //TODO leave this for testing
    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge(config.pubsubRevertRequestSubscription, ackId);
  }
}
