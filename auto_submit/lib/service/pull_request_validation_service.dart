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
import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/validations/validation_filter.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

class PullRequestValidationService extends ValidationService {
  PullRequestValidationService(Config config, {RetryOptions? retryOptions})
      : super(config, retryOptions: retryOptions) {
    /// Validates a PR marked with the reverts label.
    approverService = ApproverService(config);
  }

  ApproverService? approverService;

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
    if (await shouldProcess(messagePullRequest)) {
      await processPullRequest(
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
    final (currentPullRequest, labelNames) = await getPrWithLabels(pullRequest);
    return (currentPullRequest.state == 'open' && labelNames.contains(Config.kAutosubmitLabel));
  }

  /// Processes a PullRequest running several validations to decide whether to
  /// land the commit or remove the autosubmit label.
  Future<void> processPullRequest({
    required Config config,
    required QueryResult result,
    required github.PullRequest messagePullRequest,
    required String ackId,
    required PubSub pubsub,
  }) async {
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int prNumber = messagePullRequest.number!;

    if (messagePullRequest.isMergeQueueEnabled) {
      if (result.repository!.pullRequest!.isInMergeQueue) {
        log.info(
          '${slug.fullName}/$prNumber is already in the merge queue. Skipping.',
        );
        return;
      }
    }

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    // filter out validations here
    final ValidationFilter validationFilter = ValidationFilter(
      config: config,
      processMethod: ProcessMethod.processAutosubmit,
      repositoryConfiguration: repositoryConfiguration,
    );
    final Set<Validation> validations = validationFilter.getValidations();

    final Map<String, ValidationResult> validationsMap = <String, ValidationResult>{};
    final GithubService githubService = await config.createGithubService(slug);

    // get the labels before validation so that we can detect all labels.
    // TODO (https://github.com/flutter/flutter/issues/132811) remove this after graphql is removed.
    final github.PullRequest updatedPullRequest = await githubService.getPullRequest(slug, messagePullRequest.number!);

    /// Runs all the validation defined in the service.
    /// If the runCi flag is false then we need a way to not run the ciSuccessful validation.
    for (Validation validation in validations) {
      log.info('${slug.fullName}/$prNumber running validation ${validation.name}');
      final ValidationResult validationResult = await validation.validate(
        result,
        updatedPullRequest,
      );
      validationsMap[validation.name] = validationResult;
    }

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    for (MapEntry<String, ValidationResult> result in validationsMap.entries) {
      if (!result.value.result && result.value.action == Action.REMOVE_LABEL) {
        final String commmentMessage = result.value.message.isEmpty ? 'Validations Fail.' : result.value.message;
        final String message = 'auto label is removed for ${slug.fullName}/$prNumber, due to $commmentMessage';
        await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
        await githubService.createComment(slug, prNumber, message);
        log.info(message);
        shouldReturn = true;
      }
    }

    if (shouldReturn) {
      log.info(
        'The pr ${slug.fullName}/$prNumber with message: $ackId should be acknowledged due to validation failure.',
      );
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
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
    final MergeResult processed = await submitPullRequest(
      config: config,
      messagePullRequest: messagePullRequest,
    );

    if (!processed.result) {
      final String message = 'auto label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
      await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
      await githubService.createComment(slug, prNumber, message);
      log.info(message);
    } else {
      // Remove the autosubmit label post enqueue/merge to avoid infinite loops.
      // Here's an example of an infinite loop:
      //
      // 1. Autosubmit bot is notified that a PR is ready (reviewed, all green, has `autosubmit` label).
      // 2. Autosubmit bot puts the PR onto the merge queue.
      // 3. The PR fails some tests in the merge queue.
      // 4. Github kicks the PR back, removing it fom the merge queue.
      // 5. GOTO step 1.
      //
      // Removing the `autosubmit` label will prevent the autosubmit bot from
      // repeating the process, until a human looks at the PR, decides that it's
      // ready again, and manually adds the `autosubmit` label on it.
      await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);

      log.info('Pull Request ${slug.fullName}/$prNumber was merged successfully!');
      log.info('Attempting to insert a pull request record into the database for $prNumber');
      await insertPullRequestRecord(
        config: config,
        pullRequest: messagePullRequest,
        pullRequestType: PullRequestChangeType.change,
      );
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }
}
