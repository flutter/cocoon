// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/is_release_branch.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../../protos.dart' as pb;
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
      case 'merge_group':
        final result = await _handleMergeGroup(
          webhook.payload,
          messagePublishedOn: DateTime.parse(message.publishTime!),
        );
        return result.toResponse();
      case 'check_run':
        final event = jsonDecode(webhook.payload) as Map<String, dynamic>;
        final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(event);
        final result = await scheduler.processCheckRun(checkRunEvent);
        return result.toResponse();
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
      // Ignore the rest of the events.
      case 'ready_for_review':
      case 'unlabeled':
      case 'assigned':
      case 'locked':
      case 'review_request_removed':
      case 'review_requested':
      case 'unassigned':
      case 'unlocked':
        break;
    }
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
    final cocoon_checks.MergeGroupEvent(:mergeGroup, :action, :reason) =
        mergeGroupEvent;
    final headSha = mergeGroup.headSha;
    final slug = mergeGroupEvent.repository!.slug();

    // See the API reference:
    // https://docs.github.com/en/webhooks/webhook-events-and-payloads#merge_group
    log.info('Processing $action for merge queue @ $headSha');
    switch (action) {
      // A merge group (a group of PRs to be tested a merged together) was
      // created and Github is requesting checks to be performed before merging
      // into the main branch. Cocoon should kick off CI jobs needed to verify
      // the PR group.
      case 'checks_requested':
        log.info('Checks requests for merge queue @ $headSha');

        if (!await _shaExistsInGob(slug, headSha)) {
          // There is a chance the branch has been deleted, and this is a stale
          // merge queue pub-sub message that will *never* complete. Check and
          // see if the message is a tad-old (>=15m), and if it is, check if
          // the cooresponding branch on GitHub has been deleted.
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

      // A merge group was deleted. This can happen when a PR is pulled from the
      // merge queue. All CI jobs pertaining to this merge group should be
      // stopped to save CI resources, as Github will no longer merge this group
      // into the main branch.
      case 'destroyed':
        log.info(
          'Merge group destroyed for $slug/$headSha because it was $reason.',
        );
        if (reason == 'invalidated' || reason == 'dequeued') {
          await scheduler.cancelDestroyedMergeGroupTargets(headSha: headSha);
        } else if (reason == 'merged') {
          log.info('Merge group for $slug/$headSha was merged successfully.');
        } else {
          log.warn(
            'Unrecognized reason for merge group destroyed event: $reason',
          );
        }
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
        pr.labels?.any((label) => label.name == Config.kAutosubmitLabel) ??
        false;
    if (hasAutosubmitLabel) {
      await githubService.removeLabel(
        slug,
        pr.number!,
        Config.kAutosubmitLabel,
      );
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
}
