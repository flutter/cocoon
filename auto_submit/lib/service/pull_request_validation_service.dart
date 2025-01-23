// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/validations/validation_filter.dart';
import 'package:cocoon_server/logging.dart';
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
    final slug = messagePullRequest.base!.repo!.slug();
    final fullPullRequest = await getFullPullRequest(slug, messagePullRequest.number!);
    if (shouldProcess(fullPullRequest)) {
      await processPullRequest(
        config: config,
        result: await getNewestPullRequestInfo(config, messagePullRequest),
        pullRequest: fullPullRequest,
        ackId: ackId,
        pubsub: pubsub,
      );
    } else {
      log.info('Should not process ${messagePullRequest.toJson()}, and ack the message.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
    }
  }

  bool shouldProcess(github.PullRequest pullRequest) {
    final labelNames = pullRequest.labelNames;
    final containsLabelsNeedingValidation =
        labelNames.contains(Config.kAutosubmitLabel) || labelNames.contains(Config.kEmergencyLabel);
    return pullRequest.state == 'open' && containsLabelsNeedingValidation;
  }

  /// Processes a PullRequest running several validations to decide whether to
  /// land the commit or remove the autosubmit label.
  Future<void> processPullRequest({
    required Config config,
    required QueryResult result,
    required github.PullRequest pullRequest,
    required String ackId,
    required PubSub pubsub,
  }) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final int prNumber = pullRequest.number!;

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

    final processor = _PullRequestValidationProcessor(
      validationService: this,
      githubService: await config.createGithubService(slug),
      config: config,
      result: result,
      pullRequest: pullRequest,
      ackId: ackId,
      pubsub: pubsub,
    );
    await processor.process();
  }
}

/// A helper class that breaks down the logic into multiple smaller methods, and
/// provides common objects to all methods that need them.
class _PullRequestValidationProcessor {
  _PullRequestValidationProcessor({
    required this.validationService,
    required this.githubService,
    required this.config,
    required this.result,
    required this.pullRequest,
    required this.ackId,
    required this.pubsub,
  })  : slug = pullRequest.base!.repo!.slug(),
        prNumber = pullRequest.number!;

  final PullRequestValidationService validationService;
  final GithubService githubService;
  final Config config;
  final QueryResult result;
  final github.PullRequest pullRequest;
  final String ackId;
  final PubSub pubsub;
  final github.RepositorySlug slug;
  final int prNumber;

  Future<void> process() async {
    final hasEmergencyLabel = pullRequest.labelNames.contains(Config.kEmergencyLabel);
    final hasAutosubmitLabel = pullRequest.labelNames.contains(Config.kAutosubmitLabel);

    if (hasEmergencyLabel) {
      final didEmergencyProcessCleanly = await _processEmergency();
      if (!didEmergencyProcessCleanly) {
        // The emergency label failed to process cleanly. Do not continue processing
        // the "autosubmit" label, as it may not be safe. The author assumed that
        // the combination of both labels would cleanly land, and it didn't.
        if (hasAutosubmitLabel) {
          await _removeAutosubmitLabel('emergency label processing failed');
        }
        await pubsub.acknowledge('auto-submit-queue-sub', ackId);
        return;
      }
    }

    if (hasAutosubmitLabel) {
      await _processAutosubmit();
    } else {
      log.info('Ack the processed message : $ackId.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
    }
  }

  /// Processes the "emergency" label.
  ///
  /// Returns true, if the processing succeeded and the validation should move
  /// onto the "autosubmit" label. The primary result of a successful processing
  /// of the "emergency" label is the unlocking of the "Merge Queue Guard" check
  /// run, which allows the respective PR to be enqueued either manually using
  /// GitHub UI, or via the "autosubmit" label.
  ///
  /// Returns false, if the processing failed, the "Merge Queue Guard" was not
  /// unlocked, and any further validation should stop.
  Future<bool> _processEmergency() async {
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    // filter out validations here
    final ValidationFilter validationFilter = ValidationFilter(
      config: config,
      processMethod: ProcessMethod.processEmergency,
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
        pullRequest,
      );
      validationsMap[validation.name] = validationResult;
    }

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    for (final MapEntry(key: _, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.REMOVE_LABEL) {
        final String commmentMessage = value.message.isEmpty ? 'Validations Fail.' : value.message;
        final String message =
            '${Config.kEmergencyLabel} label is removed for ${slug.fullName}/$prNumber, due to $commmentMessage';
        await githubService.removeLabel(slug, prNumber, Config.kEmergencyLabel);
        await githubService.createComment(slug, prNumber, message);
        log.info(message);
        shouldReturn = true;
      }
    }

    if (shouldReturn) {
      log.info('The pr ${slug.fullName}/$prNumber is not eligible for emergency landing.');
      return false;
    }

    // If PR has some failures to ignore temporarily do nothing and continue.
    for (final MapEntry(:key, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.IGNORE_TEMPORARILY) {
        log.info(
          'Temporarily ignoring processing of ${slug.fullName}/$prNumber due to $key failing validation.',
        );
        return true;
      }
    }

    // At this point all validations passed, and the PR can proceed to landing
    // as an emergency.
    final guard = (await githubService.getCheckRunsFiltered(
      slug: slug,
      ref: pullRequest.base!.ref!,
      checkName: Config.kMergeQueueLockName,
    ))
        .singleOrNull;

    if (guard == null) {
      log.severe(
        'Failed to process the emergency label in ${slug.fullName}/$prNumber. '
        '"kMergeQueueLockName" check run is missing.',
      );
      return false;
    }

    await githubService.updateCheckRun(
      slug: slug,
      checkRun: guard,
      status: github.CheckRunStatus.completed,
      conclusion: github.CheckRunConclusion.success,
    );

    log.info('Unlocked merge guard for ${slug.fullName}/$prNumber to allow it to land as an emergency.');
    return true;
  }

  Future<void> _processAutosubmit() async {
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    // filter out validations here
    final ValidationFilter validationFilter = ValidationFilter(
      config: config,
      processMethod: ProcessMethod.processAutosubmit,
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
        pullRequest,
      );
      validationsMap[validation.name] = validationResult;
    }

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    for (final MapEntry(key: _, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.REMOVE_LABEL) {
        final String commentMessage = value.message.isEmpty ? 'Validations Fail.' : value.message;
        await _removeAutosubmitLabel(commentMessage);
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
    for (final MapEntry(:key, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.IGNORE_TEMPORARILY) {
        log.info(
          'Temporarily ignoring processing of ${slug.fullName}/$prNumber due to $key failing validation.',
        );
        return;
      }
    }

    // If we got to this point it means we are ready to submit the PR.
    final MergeResult processed = await validationService.submitPullRequest(
      config: config,
      pullRequest: pullRequest,
    );

    if (!processed.result) {
      final String message = 'auto label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
      await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
      await githubService.createComment(slug, prNumber, message);
      log.info(message);
    } else {
      log.info('Pull Request ${slug.fullName}/$prNumber was ${processed.method.pastTenseLabel} successfully!');
      log.info('Attempting to insert a pull request record into the database for $prNumber');
      await validationService.insertPullRequestRecord(
        config: config,
        pullRequest: pullRequest,
        pullRequestType: PullRequestChangeType.change,
      );
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }

  Future<void> _removeAutosubmitLabel(String reason) async {
    final String message =
        '${Config.kAutosubmitLabel} label was removed for ${slug.fullName}/$prNumber, because $reason';
    await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
    await githubService.createComment(slug, prNumber, message);
    log.info(message);
  }
}
