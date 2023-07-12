// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/process_method.dart';
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
    if (await shouldProcess(messagePullRequest)) {
      await processRevertRequest(
        config: config,
        result: await getNewestPullRequestInfo(config, messagePullRequest),
        messagePullRequest: messagePullRequest,
        ackId: ackId,
        pubsub: pubsub,
      );
    } else {
      log.info('Should not process ${messagePullRequest.toJson()}, and ack the message.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
    }
  }

  Future<bool> shouldProcess(github.PullRequest pullRequest) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    final github.PullRequest currentPullRequest = await githubService.getPullRequest(slug, pullRequest.number!);
    final List<String> labelNames = (currentPullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    if (currentPullRequest.state == 'open' && labelNames.contains(Config.kRevertLabel)) {
      // TODO (ricardoamador) this will not make sense now that reverts happen from closed.
      // we can open the pull request but who do we assign it to? The initiating author?
      if (!repositoryConfiguration.supportNoReviewReverts) {
        log.info(
          'Cannot allow revert request (${slug.fullName}/${pullRequest.number}) without review. Processing as regular pull request.',
        );
        final int issueNumber = currentPullRequest.number!;
        // Remove the revert label and add the autosubmit label.
        await githubService.removeLabel(slug, issueNumber, Config.kRevertLabel);
        await githubService.addLabels(slug, issueNumber, [Config.kAutosubmitLabel]);
        return false;
      }
      return true;
    }
    return false;
  }

  /// TODO this becomes validate to determine if the pR status is good to proceed.
  /// Checks if a pullRequest is still open and with autosubmit label before trying to process it.
  Future<ProcessMethod> processPullRequestMethod(github.PullRequest pullRequest) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    final github.PullRequest currentPullRequest = await githubService.getPullRequest(slug, pullRequest.number!);
    final List<String> labelNames = (currentPullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    if (currentPullRequest.state == 'open' && labelNames.contains(Config.kRevertLabel)) {
      // TODO (ricardoamador) this will not make sense now that reverts happen from closed.
      // we can open the pull request but who do we assign it to? The initiating author?
      if (!repositoryConfiguration.supportNoReviewReverts) {
        log.info(
          'Cannot allow revert request (${slug.fullName}/${pullRequest.number}) without review. Processing as regular pull request.',
        );
        final int issueNumber = currentPullRequest.number!;
        // Remove the revert label and add the autosubmit label.
        await githubService.removeLabel(slug, issueNumber, Config.kRevertLabel);
        await githubService.addLabels(slug, issueNumber, [Config.kAutosubmitLabel]);
        return ProcessMethod.processAutosubmit;
      }
      return ProcessMethod.processRevert;
    } else if (currentPullRequest.state == 'open' && labelNames.contains(Config.kAutosubmitLabel)) {
      return ProcessMethod.processAutosubmit;
    } else {
      return ProcessMethod.doNotProcess;
    }
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
    // get validations to be run here.
    // TODO this used to be defined in the constructor but will be moved to validation filter.
    revertValidation = revertValidation ?? Revert(config: config);
    final ValidationResult revertValidationResult = await revertValidation!.validate(
      result,
      messagePullRequest,
    );

    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int prNumber = messagePullRequest.number!;
    final GithubService githubService = await config.createGithubService(slug);

    if (revertValidationResult.result) {
      // Approve the pull request automatically as it has been validated.
      await approverService!.revertApproval(result, messagePullRequest);

      final MergeResult processed = await processMerge(
        config: config,
        messagePullRequest: messagePullRequest,
      );

      if (processed.result) {
        log.info('Revert request ${slug.fullName}/$prNumber was merged successfully.');
        log.info('Insert a revert pull request record into the database for pr ${slug.fullName}/$prNumber');
        await insertPullRequestRecord(
          config: config,
          pullRequest: messagePullRequest,
          pullRequestType: PullRequestChangeType.revert,
        );
      } else {
        final String message = 'revert label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
        await githubService.removeLabel(slug, prNumber, Config.kRevertLabel);
        await githubService.createComment(slug, prNumber, message);
        log.info(message);
      }
    } else if (!revertValidationResult.result && revertValidationResult.action == Action.IGNORE_TEMPORARILY) {
      // if required check runs have not completed process again.
      log.info('Some of the required checks have not completed. Requeueing.');
      return;
    } else {
      // since we do not temporarily ignore anything with a revert request we
      // know we will report the error and remove the label.
      final String commentMessage =
          revertValidationResult.message.isEmpty ? 'Validations Fail.' : revertValidationResult.message;
      await githubService.removeLabel(slug, prNumber, Config.kRevertLabel);
      await githubService.createComment(slug, prNumber, commentMessage);
      log.info('revert label is removed for ${slug.fullName}, pr: $prNumber, due to $commentMessage');
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }
}
