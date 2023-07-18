// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/action/graphql_revert_method.dart';
import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

class RevertRequestValidationService extends ValidationService {
  RevertRequestValidationService(Config config, {RetryOptions? retryOptions})
      : super(config, retryOptions: retryOptions) {
    /// Validates a PR marked with the reverts label.
    approverService = ApproverService(config);
  }

  ApproverService? approverService;
  Revert? revertValidation;

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
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
    }
  }

  Future<bool> shouldProcess(github.PullRequest pullRequest, List<String> labelNames) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    // final (currentPullRequest, labelNames) = await getPrWithLabels(pullRequest);
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    if (pullRequest.state == 'open' && labelNames.contains(Config.kRevertLabel)) {
      // TODO (ricardoamador) this will not make sense now that reverts happen from closed.
      // we can open the pull request but who do we assign it to? The initiating author?
      if (!repositoryConfiguration.supportNoReviewReverts) {
        log.info(
          'Cannot allow revert request (${slug.fullName}/${pullRequest.number}) without review. Processing as regular pull request.',
        );
        final int issueNumber = pullRequest.number!;
        // Remove the revert label and add the autosubmit label.
        await githubService.removeLabel(slug, issueNumber, Config.kRevertLabel);
        await githubService.addLabels(slug, issueNumber, [Config.kAutosubmitLabel]);
        return false;
      }
      return true;
    } else if (pullRequest.state == 'closed' && labelNames.contains(Config.kRevertLabel)) {
      // Check the timestamp here as well since we do not want to allow reverts older than
      // 24 hours.
      //
      // There is some nuance here as we still can process and create the revert which
      // will take us to the case above but we need to check again if there are
      // no review reverts supported.
      // if (DateTime.now().difference(currentPullRequest.mergedAt!).inHours > 24) {
      //   log.info('Time to revert pull request ${slug.fullName}/${currentPullRequest.number} has elapsed. You need to open the revert manually and process as a regular pull request.');
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

    // two cases:
    //   issue is open
    //      if author is autosubmit, validate and merge.
    //   issue is closed
    //      create the revert request

    switch (messagePullRequest.state!) {
      case 'open': {
        // this means this pull request was opened by the autosubmit[bot] account and
        // needs to be processed.
      }
      case 'closed': {
        final GraphQLRevertMethod graphQLRevertMethod = GraphQLRevertMethod();
        final PullRequest autoSubQueryPullRequest = await graphQLRevertMethod.createRevert(config, messagePullRequest);
        // We only need the number from this.
        log.info('Returned pull request number is ${autoSubQueryPullRequest.number}');
      }
    }


    // get validations to be run here.
    // TODO this used to be defined in the constructor but will be moved to validation filter.
    // revertValidation = revertValidation ?? Revert(config: config);
    // final ValidationResult revertValidationResult = await revertValidation!.validate(
    //   result,
    //   messagePullRequest,
    // );

    // final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    // final int prNumber = messagePullRequest.number!;
    // final GithubService githubService = await config.createGithubService(slug);

    // if (revertValidationResult.result) {
    //   // Approve the pull request automatically as it has been validated.
    //   await approverService!.revertApproval(result, messagePullRequest);

    //   final MergeResult processed = await processMerge(
    //     config: config,
    //     messagePullRequest: messagePullRequest,
    //   );

    //   if (processed.result) {
    //     log.info('Revert request ${slug.fullName}/$prNumber was merged successfully.');
    //     log.info('Insert a revert pull request record into the database for pr ${slug.fullName}/$prNumber');
    //     await insertPullRequestRecord(
    //       config: config,
    //       pullRequest: messagePullRequest,
    //       pullRequestType: PullRequestChangeType.revert,
    //     );
    //   } else {
    //     final String message = 'revert label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
    //     await githubService.removeLabel(slug, prNumber, Config.kRevertLabel);
    //     await githubService.createComment(slug, prNumber, message);
    //     log.info(message);
    //   }
    // } else if (!revertValidationResult.result && revertValidationResult.action == Action.IGNORE_TEMPORARILY) {
    //   // if required check runs have not completed process again.
    //   log.info('Some of the required checks have not completed. Requeueing.');
    //   return;
    // } else {
    //   // since we do not temporarily ignore anything with a revert request we
    //   // know we will report the error and remove the label.
    //   final String commentMessage =
    //       revertValidationResult.message.isEmpty ? 'Validations Fail.' : revertValidationResult.message;
    //   await githubService.removeLabel(slug, prNumber, Config.kRevertLabel);
    //   await githubService.createComment(slug, prNumber, commentMessage);
    //   log.info('revert label is removed for ${slug.fullName}, pr: $prNumber, due to $commentMessage');
    //   log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
    // }

    // log.info('Ack the processed message : $ackId.');
    // await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }
}
