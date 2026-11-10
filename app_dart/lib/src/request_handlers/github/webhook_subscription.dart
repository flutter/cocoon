// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/is_release_branch.dart';
import 'package:cocoon_common/labels.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../../protos.dart' as pb;
import '../../foundation/github_checks_util.dart';
import '../../model/github/checks.dart' as cocoon_checks;
import '../../model/github/labels.dart';
import '../../model/github/workflow_job.dart' as workflow_job;
import '../../request_handling/exceptions.dart';
import '../../request_handling/subscription_handler.dart';
import '../../service/commit_service.dart';
import '../../service/scheduler/process_check_run_result.dart';

/// Subscription for processing GitHub webhooks.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/github-webhooks-sub?project=flutter-dashboard&tab=overview
///
/// This endpoint enables Cocoon to recover from outages.
///
/// This endpoint takes in a POST request with the GitHub event JSON.
// TODO(chillers): There's potential now to split this into seprate subscriptions
// for various activities (such as infra vs releases). This would mitigate
// breakages across Cocoon.
final class GithubWebhookSubscription extends SubscriptionHandler {
  static const _estimatedGitOnBorgMaximumSyncDuration = Duration(minutes: 15);

  /// Creates a subscription for processing GitHub webhooks.
  GithubWebhookSubscription({
    required super.cache,
    required super.config,
    required this.scheduler,
    required this.gerritService,
    required this.commitService,
    required this.firestore,
    this.issueService,
    this.wantLgtmReconciler,
    super.authProvider,
    this.pullRequestLabelProcessorProvider = PullRequestLabelProcessor.new,
    @visibleForTesting DateTime Function() now = DateTime.now,
    // Gets the initial github events from this sub after the webhook uploads them.
  }) : _now = now,
       super(subscriptionName: 'github-webhooks-sub');

  final DateTime Function() _now;

  /// Cocoon scheduler to trigger tasks against changes from GitHub.
  final Scheduler scheduler;

  /// To verify whether a commit was mirrored to GoB.
  final GerritService gerritService;

  /// Used to handle push events and create commits based on those events.
  final CommitService commitService;

  final FirestoreService firestore;
  final PullRequestLabelProcessorProvider pullRequestLabelProcessorProvider;
  final IssueService? issueService;
  final WantLgtmReconciler? wantLgtmReconciler;

  @override
  Future<Response> post(Request request) async {
    if (message.data == null || message.data!.isEmpty) {
      log.warn('GitHub webhook message was empty. No-oping');
      return Response.emptyOk;
    }

    final webhook = pb.GithubWebhookMessage.fromJson(message.data!);

    log.info('Processing ${webhook.event}');
    log.debug(webhook.payload);
    switch (webhook.event) {
      case 'pull_request':
        return _handlePullRequest(webhook.payload);
      case 'issues':
        return _handleIssues(webhook.payload);
      case 'merge_group':
        final result = await _handleMergeGroup(
          webhook.payload,
          messagePublishedOn: DateTime.parse(message.publishTime!),
        );
        return result.toResponse();
      case 'check_run':
        return _handleCheckRun(webhook.payload);
      case 'pull_request_review':
        return _handlePullRequestReview(webhook.payload);
      case 'push':
        final event = jsonDecode(webhook.payload) as Map<String, dynamic>;
        final branch = (event['ref'] as String).split(
          '/',
        )[2]; // Eg: refs/heads/beta would return beta.
        final repository = event['repository']['name'] as String;
        // If the branch is beta/stable, then a commit wasn't created through a PR,
        // meaning the commit needs to be added to the Firestore here instead.
        if (repository == 'flutter' &&
            (branch == 'stable' || branch == 'beta')) {
          await commitService.handlePushGithubRequest(event);
        }
        break;
      case 'create':
        final createEvent = CreateEvent.fromJson(
          json.decode(webhook.payload) as Map<String, dynamic>,
        );
        // Create a commit object for candidate branches in the Firestore so
        // dart-internal builds that are triggered by the initial branch
        // creation have an associated commit.
        if (isReleaseCandidateBranch(branchName: createEvent.ref!)) {
          log.debug(
            'Branch ${createEvent.ref} is a candidate branch, creating new '
            'commit in the Firestore',
          );
          await commitService.handleCreateGithubRequest(createEvent);
        }
      case 'workflow_job':
        try {
          final job = workflow_job.WorkflowJobEvent.fromJson(
            json.decode(webhook.payload) as Map<String, Object?>,
          );
          log.debug('workflow_job: $job');
          await scheduler.processWorkflowJob(job);
        } catch (e, s) {
          log.warn(
            'Failed to parse workflow_job event: ${webhook.payload}',
            e,
            s,
          );
        }
    }

    return Response.emptyOk;
  }

  /// Handles a GitHub webhook with the event type "pull_request".
  ///
  /// Regarding merged pull request events: the commit must be mirrored to GoB
  /// before we can trigger postsubmit tasks. If the commit is not found, the
  /// event will be failed so it can be retried. As of Jan 26, 2023, the
  /// retention policy for Pub/Sub messages is 7 days. This event will be
  /// retried with exponential backoff within that time period. The GoB mirror
  /// should be caught up within that time frame via either the internal
  /// mirroring service or [VacuumGithubCommits].
  Future<Response> _handlePullRequest(String rawRequest) async {
    final pullRequestEvent = _getPullRequestEvent(rawRequest);
    if (pullRequestEvent == null) {
      throw const BadRequestException('Expected pull request event.');
    }
    final eventAction = pullRequestEvent.action;
    final pr = pullRequestEvent.pullRequest!;
    final crumb = '$GithubWebhookSubscription._handlePullRequest(${pr.number})';

    final slug = pr.base!.repo!.slug();
    if (!config.supportedRepos.contains(slug)) {
      log.warn(
        '$crumb: asked to handle unsupported repo $slug for ${pr.htmlUrl}',
      );
      throw const InternalServerError('Unsupported repository');
    }

    final context = PullRequestEventContext(
      cache: cache,
      firestore: firestore,
      config: config,
      scheduler: scheduler,
      gerritService: gerritService,
      pullRequestLabelProcessorProvider: pullRequestLabelProcessorProvider,
      wantLgtmReconciler: await _getReconciler(slug, prNumber: pr.number),
    );

    // See the API reference:
    // https://developer.github.com/v3/activity/events/types/#pullrequestevent
    // which unfortunately is a bit light on explanations.
    log.info('$crumb: processing $eventAction for ${pr.htmlUrl}');
    switch (eventAction) {
      case 'closed':
        return await PullRequestManager.handleClosed(
          pullRequestEvent,
          context,
          _processPullRequestClosed,
        );
      case 'edited':
        await PullRequestManager.handleEdited(pullRequestEvent, context);
        break;
      case 'opened':
        await PullRequestManager.handleOpened(pullRequestEvent, context);
        break;
      case 'reopened':
        await PullRequestManager.handleReopened(pullRequestEvent, context);
        break;
      case 'labeled':
        log.info(
          '$crumb: PR labels = [${pr.labels?.map((label) => '"${label.name}"').join(', ')}]',
        );
        final labelEvent = _getLabeledEvent(rawRequest);
        final labelName = labelEvent?.label.name;
        final labelId = labelEvent?.label.id;
        await PullRequestManager.handleLabeled(
          pullRequestEvent,
          context,
          labelName,
          labelId,
        );
        break;
      case 'dequeued':
        await _respondToPullRequestDequeued(pullRequestEvent);
        break;
      case 'synchronize':
        await PullRequestManager.handleSynchronize(pullRequestEvent, context);
        break;
      case 'ready_for_review':
        await PullRequestManager.handleReadyForReview(
          pullRequestEvent,
          context,
        );
        break;
      case 'review_request_removed':
      case 'review_requested':
        await _handleReviewRequestChanged(pullRequestEvent, context);
        break;
      // Ignore the rest of the events.
      case 'unlabeled':
      case 'assigned':
      case 'locked':
      case 'unassigned':
      case 'unlocked':
        break;
    }
    return Response.emptyOk;
  }

  Future<void> _handleReviewRequestChanged(
    PullRequestEvent event,
    PullRequestEventContext context,
  ) async {
    final prNumber = event.pullRequest?.number;
    final repository = event.repository;
    if (prNumber == null || repository == null) {
      return;
    }
    final slug = repository.slug();
    await PullRequestManager.runWithPrLock<void>(
      slug: slug,
      prNumber: prNumber,
      cache: cache,
      action: () async {
        try {
          await context.wantLgtmReconciler?.reconcilePullRequest(
            slug,
            prNumber,
            pullRequest: event.pullRequest,
            triggerReason: event.action,
          );
        } catch (e, s) {
          log.error(
            'Error reconciling WANT_LGTM on review request change $slug #$prNumber: $e\n$s',
          );
        }
      },
    );
  }

  Future<Response> _handleCheckRun(String rawRequest) async {
    final event = jsonDecode(rawRequest) as Map<String, dynamic>;
    final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(event);
    final checkRun = checkRunEvent.checkRun;
    if (checkRun?.name == Config.kWantLgtmCheckName) {
      return _handleWantLgtmCheckRun(checkRunEvent);
    }
    final result = await scheduler.processCheckRun(checkRunEvent);
    return result.toResponse();
  }

  Future<Response> _handleWantLgtmCheckRun(
    cocoon_checks.CheckRunEvent checkRunEvent,
  ) async {
    if (checkRunEvent.action != 'rerequested') {
      return Response.emptyOk;
    }
    final checkRun = checkRunEvent.checkRun;
    final checkRunId = checkRun?.id;
    var prNumber = checkRun?.pullRequests?.firstOrNull?.number;
    if (prNumber == null && checkRunId != null) {
      final state = await WantLgtmState.findByCheckRunId(
        firestoreService: firestore,
        checkRunId: checkRunId,
      );
      prNumber = state?.pr;
    }
    final repository = checkRunEvent.repository;
    if (prNumber == null || repository == null) {
      return Response.emptyOk;
    }
    final slug = repository.slug();
    final targetPrNumber = prNumber;
    await PullRequestManager.runWithPrLock<void>(
      slug: slug,
      prNumber: targetPrNumber,
      cache: cache,
      action: () async {
        try {
          final reconciler = await _getReconciler(
            slug,
            prNumber: targetPrNumber,
          );
          await reconciler?.reconcilePullRequest(
            slug,
            targetPrNumber,
            triggerReason: 'check_run_rerequested',
          );
        } catch (e, s) {
          log.error(
            'Error reconciling WANT_LGTM on check_run rerequested $slug #$targetPrNumber: $e\n$s',
          );
        }
      },
    );
    return Response.emptyOk;
  }

  /// Handles a GitHub webhook with the event type "merge_group".
  ///
  /// A merge group contains commits from multiple pull requests. Each pull
  /// request is squashed into one commit, then that commit is stacked on top of
  /// other commits in the queue. A merge group is therefore not associated with
  /// any one pull request. Instead, its `head_sha` (the SHA of the top-most
  /// commit) is the one the CI runs all the checks against. If the checks pass,
  /// the group of commits is pushed onto the main/master branch.
  ///
  /// The commit SHAs in the merge group are not the same as the commit SHAs in
  /// the pull request. Merge group SHAs are rewritten while they are stacked on
  /// top of each other.
  @useResult
  Future<ProcessCheckRunResult> _handleMergeGroup(
    String rawRequest, {
    required DateTime messagePublishedOn,
  }) async {
    final request = json.decode(rawRequest);

    if (request is! Map<String, Object?>) {
      throw BadRequestException('Malformed merge_group request:\n$rawRequest');
    }

    final mergeGroupEvent = cocoon_checks.MergeGroupEvent.fromJson(request);
    final cocoon_checks.MergeGroupEvent(:mergeGroup, :action) = mergeGroupEvent;
    final headSha = mergeGroup.headSha;

    // See the API reference:
    // https://docs.github.com/en/webhooks/webhook-events-and-payloads#merge_group
    log.info('Processing $action for merge queue @ $headSha');
    return switch (action) {
      'checks_requested' => _handleMergeGroupChecksRequested(
        mergeGroupEvent,
        messagePublishedOn: messagePublishedOn,
      ),
      'destroyed' => _handleMergeGroupDestroyed(mergeGroupEvent),
      _ => const ProcessCheckRunResult.success(),
    };
  }

  Future<ProcessCheckRunResult> _handleMergeGroupChecksRequested(
    cocoon_checks.MergeGroupEvent mergeGroupEvent, {
    required DateTime messagePublishedOn,
  }) async {
    final cocoon_checks.MergeGroupEvent(:mergeGroup) = mergeGroupEvent;
    final headSha = mergeGroup.headSha;
    final slug = mergeGroupEvent.repository!.slug();

    log.info('Checks requests for merge queue @ $headSha');

    if (!await _shaExistsInGob(slug, headSha)) {
      // There is a chance the branch has been deleted, and this is a stale
      // merge queue pub-sub message that will *never* complete. Check and
      // see if the message is a tad-old (>=15m), and if it is, check if
      // the corresponding branch on GitHub has been deleted.
      //
      // See https://github.com/flutter/flutter/issues/166078.
      final duration = _now().difference(messagePublishedOn);
      if (duration >= _estimatedGitOnBorgMaximumSyncDuration) {
        // Check GitHub.
        final githubService = await config.createGithubService(slug);
        try {
          await githubService.getReference(slug, mergeGroup.headRef);
          log.info(
            '$slug/$headSha was not found on GoB, but was found on GitHub.',
          );
        } on github.NotFound {
          final message =
              '$slug/$headSha was not found on GoB and appears deleted on '
              'GitHub.';
          log.info(message);
          return ProcessCheckRunResult.missingEntity(message);
        }
      }
      return ProcessCheckRunResult.retrySoon(
        '$slug/$headSha was not found on GoB. Failing so this event can be retried',
      );
    }
    log.info(
      '$slug/$headSha was found on GoB mirror. Scheduling merge group tasks',
    );
    await scheduler.handleMergeGroupEvent(mergeGroupEvent: mergeGroupEvent);
    if (config.flags.wantLgtm.isEnabledForRepo(slug)) {
      try {
        final headBranch = mergeGroup.headRef.replaceFirst('refs/heads/', '');
        final (:parsed, :pullRequestNumber, branch: _) =
            tryParseGitHubMergeQueueBranch(headBranch);
        final prNumber = parsed ? pullRequestNumber : 0;
        final reconciler = await _getReconciler(slug);
        await reconciler?.reconcileMergeGroup(
          slug: slug,
          prNumber: prNumber,
          mergeGroupSha: headSha,
        );
      } catch (e, s) {
        log.error(
          'Error reconciling WANT_LGTM in merge group for $slug: $e\n$s',
        );
      }
    }
    return const ProcessCheckRunResult.success();
  }

  Future<ProcessCheckRunResult> _handleMergeGroupDestroyed(
    cocoon_checks.MergeGroupEvent mergeGroupEvent,
  ) async {
    final cocoon_checks.MergeGroupEvent(:mergeGroup, :reason) = mergeGroupEvent;
    final headSha = mergeGroup.headSha;
    final slug = mergeGroupEvent.repository!.slug();

    log.info(
      'Merge group destroyed for $slug/$headSha because it was $reason.',
    );
    switch (reason) {
      case 'invalidated' || 'dequeued':
        await scheduler.cancelDestroyedMergeGroupTargets(headSha: headSha);
      case 'merged':
        log.info('Merge group for $slug/$headSha was merged successfully.');
      default:
        log.warn(
          'Unrecognized reason for merge group destroyed event: $reason',
        );
    }
    return const ProcessCheckRunResult.success();
  }

  Future<bool> _commitExistsInGob(PullRequest pr) async {
    final slug = pr.base!.repo!.slug();
    final sha = pr.mergeCommitSha!;
    return _shaExistsInGob(slug, sha);
  }

  Future<bool> _shaExistsInGob(RepositorySlug slug, String sha) async {
    final gobCommit = await gerritService.findMirroredCommit(slug, sha);
    return gobCommit != null;
  }

  /// Responds to the "dequeued" pull request event.
  ///
  /// See also: https://docs.github.com/en/webhooks/webhook-events-and-payloads?actionType=dequeued#pull_request
  Future<void> _respondToPullRequestDequeued(
    PullRequestEvent pullRequestEvent,
  ) async {
    final pr = pullRequestEvent.pullRequest!;
    final slug = pullRequestEvent.repository!.slug();
    final githubService = await config.createGithubService(slug);

    // Remove the autosubmit label when a pull request is kicked out of the
    // merge queue to avoid infinite loops.
    //
    // An example of an infinite loop:
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
    final hasAutosubmitLabel =
        pr.labels?.any((label) => label.name == kAutosubmitLabel) ?? false;
    if (hasAutosubmitLabel) {
      await githubService.removeLabel(slug, pr.number!, kAutosubmitLabel);
    }
  }

  @useResult
  Future<ProcessCheckRunResult> _processPullRequestClosed(
    PullRequestEvent pullRequestEvent,
  ) async {
    final pr = pullRequestEvent.pullRequest!;

    // Cancel any outstanding presubmit jobs. They are useless after the PR is
    // closed. If the PR was merged, then the post-submit results will determine
    // what needs to be done about this PR (maybe it lands, or maybe it will be
    // reverted). If the PR was just closed and abandoned, well, that means we
    // don't care about it any more.
    await scheduler.cancelPreSubmitTargets(
      pullRequest: pr,
      reason: (!pr.merged!) ? 'Pull request closed' : 'Pull request merged',
    );

    if (!pr.merged!) {
      return const ProcessCheckRunResult.success();
    }

    log.debug('Pull request ${pr.number} was closed and merged.');

    if (await _commitExistsInGob(pr)) {
      log.debug(
        'Merged commit was found on GoB mirror. Scheduling postsubmit tasks...',
      );
      await scheduler.addPullRequest(pr);
      return const ProcessCheckRunResult.success();
    }
    final duration = _now().difference(pr.closedAt!);
    if (duration < _estimatedGitOnBorgMaximumSyncDuration) {
      return ProcessCheckRunResult.retrySoon(
        '${pr.mergeCommitSha!} was not found on GoB (duration=$duration). Retry.',
      );
    }
    return ProcessCheckRunResult.missingEntity(
      '${pr.mergeCommitSha!} was not found on GoB (duration=$duration).',
    );
  }

  PullRequestEvent? _getPullRequestEvent(String request) {
    try {
      return PullRequestEvent.fromJson(
        json.decode(request) as Map<String, dynamic>,
      );
    } on FormatException catch (e) {
      log.warn('Failed to parse $request', e);
      return null;
    }
  }

  Future<Response> _handleIssues(String rawRequest) async {
    final issueEvent = _getIssueEvent(rawRequest);
    if (issueEvent == null) {
      throw const BadRequestException('Expected issue event.');
    }
    if (issueService case final service?) {
      await service.handleIssueEvent(issueEvent);
    }
    return Response.emptyOk;
  }

  IssueEvent? _getIssueEvent(String request) {
    try {
      return IssueEvent.fromJson(jsonDecode(request) as Map<String, dynamic>);
    } catch (e, s) {
      log.warn('_getIssueEvent: Failed to parse $request', e, s);
      return null;
    }
  }

  LabeledEvent? _getLabeledEvent(String request) {
    try {
      return LabeledEvent.fromJson(
        json.decode(request) as Map<String, dynamic>,
      );
    } catch (e, s) {
      log.warn('_getLabeledEvent: Failed to parse $request', e, s);
      return null;
    }
  }

  Future<WantLgtmReconciler?> _getReconciler(
    RepositorySlug slug, {
    int? prNumber,
  }) async {
    if (wantLgtmReconciler != null) {
      return wantLgtmReconciler;
    }
    if (!config.flags.wantLgtm.isEnabledForRepo(slug) &&
        !await _hasInProgressWantLgtmState(slug, prNumber)) {
      return null;
    }
    final graphQLClient = await config.createGitHubGraphQLClient();
    return WantLgtmReconciler(
      config: config,
      graphQLClient: WantLgtmGraphQLClient(graphQLClient),
      checkWriter: WantLgtmCheckWriter(
        config: config,
        githubChecksUtil: const GithubChecksUtil(),
        firestoreService: firestore,
      ),
      firestoreService: firestore,
    );
  }

  Future<bool> _hasInProgressWantLgtmState(
    RepositorySlug slug,
    int? prNumber,
  ) async {
    if (prNumber == null || prNumber <= 0) {
      return false;
    }
    final existing = await WantLgtmState.fromFirestoreOrNull(
      firestoreService: firestore,
      slug: slug,
      pr: prNumber,
    );
    return existing != null && existing.checkRunStatus == 'in_progress';
  }

  Future<Response> _handlePullRequestReview(String rawRequest) async {
    final event = jsonDecode(rawRequest) as Map<String, dynamic>;
    final reviewEvent = PullRequestReviewEvent.fromJson(event);
    final action = reviewEvent.action;
    if (action != 'submitted' && action != 'dismissed') {
      return Response.emptyOk;
    }
    final repository = reviewEvent.repository;
    final pr = reviewEvent.pullRequest;
    final prNumber = pr?.number;
    if (repository == null || pr == null || prNumber == null) {
      log.warn(
        '$GithubWebhookSubscription._handlePullRequestReview: missing repo or pr',
      );
      return Response.emptyOk;
    }
    final slug = repository.slug();
    if (!config.supportedRepos.contains(slug)) {
      log.warn(
        '$GithubWebhookSubscription._handlePullRequestReview: asked to handle unsupported repo $slug for pr $prNumber',
      );
      throw const InternalServerError('Unsupported repository');
    }
    return await PullRequestManager.runWithPrLock<Response>(
      slug: slug,
      prNumber: prNumber,
      cache: cache,
      action: () async {
        try {
          final reconciler = await _getReconciler(slug, prNumber: prNumber);
          await reconciler?.reconcilePullRequest(
            slug,
            prNumber,
            pullRequest: pr,
            triggerReason: 'review_$action',
          );
        } catch (e, s) {
          log.error(
            'Error reconciling WANT_LGTM on review_$action for $slug #$prNumber: $e\n$s',
          );
        }
        return Response.emptyOk;
      },
    );
  }
}
