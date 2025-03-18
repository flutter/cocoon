// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

import '../model/auto_submit_query_result.dart';
import '../model/pull_request_data_types.dart';
import '../request_handling/pubsub.dart';
import '../validations/validation.dart';
import '../validations/validation_filter.dart';
import 'approver_service.dart';
import 'config.dart';
import 'github_service.dart';
import 'process_method.dart';
import 'validation_service.dart';

class PullRequestValidationService extends ValidationService {
  PullRequestValidationService(
    Config config, {
    RetryOptions? retryOptions,
    required this.subscription,
  }) : super(config, retryOptions: retryOptions) {
    /// Validates a PR marked with the reverts label.
    approverService = ApproverService(config);
  }

  String subscription;
  ApproverService? approverService;

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(
    github.PullRequest messagePullRequest,
    String ackId,
    PubSub pubsub,
  ) async {
    final slug = messagePullRequest.base!.repo!.slug();
    final fullPullRequest = await getFullPullRequest(
      slug,
      messagePullRequest.number!,
    );
    if (shouldProcess(fullPullRequest)) {
      await processPullRequest(
        config: config,
        result: await getNewestPullRequestInfo(config, messagePullRequest),
        pullRequest: fullPullRequest,
        ackId: ackId,
        pubsub: pubsub,
      );
    } else {
      log2.info(
        'Should not process ${messagePullRequest.toJson()}, and ack the message.',
      );
      await pubsub.acknowledge(subscription, ackId);
    }
  }

  bool shouldProcess(github.PullRequest pullRequest) {
    final labelNames = pullRequest.labelNames;
    final containsLabelsNeedingValidation =
        labelNames.contains(Config.kAutosubmitLabel) ||
        labelNames.contains(Config.kEmergencyLabel);
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
    final slug = pullRequest.base!.repo!.slug();
    final prNumber = pullRequest.number!;

    // If a pull request is currently in the merge queue do not touch it. Let
    // the merge queue merge it, or kick it out of the merge queue.
    if (pullRequest.isMergeQueueEnabled) {
      if (result.repository!.pullRequest!.isInMergeQueue) {
        log2.info(
          '${slug.fullName}/$prNumber is already in the merge queue. Skipping.',
        );
        await pubsub.acknowledge(subscription, ackId);
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
      subscription: subscription,
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
    required this.subscription,
  }) : slug = pullRequest.base!.repo!.slug(),
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

  String subscription;

  String get logCrumb => 'PullRequestValidation($slug/pull/$prNumber)';

  void logInfo(Object? message) {
    log2.info('$logCrumb: $message');
  }

  void logSevere(Object? message) {
    log2.error('$logCrumb: $message');
  }

  Future<void> process() async {
    final hasAutosubmitLabel = pullRequest.labelNames.contains(
      Config.kAutosubmitLabel,
    );

    if (hasAutosubmitLabel) {
      await _processAutosubmit();
    } else {
      logInfo('Ack the processed message : $ackId.');
      await pubsub.acknowledge(subscription, ackId);
    }
  }

  Future<void> _processAutosubmit() async {
    logInfo('processing "${Config.kAutosubmitLabel}" label');
    final repositoryConfiguration = await config.getRepositoryConfiguration(
      slug,
    );

    // filter out validations here
    final validationFilter = ValidationFilter(
      config: config,
      processMethod: ProcessMethod.processAutosubmit,
      repositoryConfiguration: repositoryConfiguration,
    );
    final validations = validationFilter.getValidations();

    final validationsMap = <String, ValidationResult>{};

    /// Runs all the validation defined in the service.
    /// If the runCi flag is false then we need a way to not run the ciSuccessful validation.
    for (var validation in validations) {
      logInfo('running validation ${validation.name}');
      final validationResult = await validation.validate(result, pullRequest);
      validationsMap[validation.name] = validationResult;
    }

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    var shouldReturn = false;
    for (final MapEntry(key: _, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.REMOVE_LABEL) {
        final commentMessage =
            value.message.isEmpty ? 'Validations Fail.' : value.message;
        await _removeAutosubmitLabel(commentMessage);
        shouldReturn = true;
      }
    }

    if (shouldReturn) {
      await pubsub.acknowledge(subscription, ackId);
      logInfo('not feasible to merge; pubsub $ackId is acknowledged.');
      return;
    }

    // If PR has some failures to ignore temporarily do nothing and continue.
    for (final MapEntry(:key, :value) in validationsMap.entries) {
      if (!value.result && value.action == Action.IGNORE_TEMPORARILY) {
        logInfo(
          'temporarily ignoring processing because $key validation failed.',
        );
        return;
      }
    }

    // If we got to this point it means we are ready to submit the PR.
    final processed = await validationService.submitPullRequest(
      config: config,
      pullRequest: pullRequest,
    );

    if (!processed.result) {
      final message =
          'auto label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
      await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
      await githubService.createComment(slug, prNumber, message);
      logInfo(message);
    } else {
      logInfo('${processed.method.pastTenseLabel} successfully!');
      logInfo(
        'Attempting to insert a pull request record into the database for $prNumber',
      );
      await validationService.insertPullRequestRecord(
        config: config,
        pullRequest: pullRequest,
        pullRequestType: PullRequestChangeType.change,
      );
    }

    logInfo('Ack the processed message : $ackId.');
    await pubsub.acknowledge(subscription, ackId);
  }

  Future<void> _removeAutosubmitLabel(String reason) async {
    final message =
        '${Config.kAutosubmitLabel} label was removed for ${slug.fullName}/$prNumber, because $reason';
    await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
    await githubService.createComment(slug, prNumber, message);
    logInfo(message);
  }
}
