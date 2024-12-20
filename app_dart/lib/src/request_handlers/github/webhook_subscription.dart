// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:meta/meta.dart';

import '../../../protos.dart' as pb;
import '../../model/gerrit/commit.dart';
import '../../model/github/checks.dart' as cocoon_checks;
import '../../request_handling/exceptions.dart';
import '../../request_handling/subscription_handler.dart';
import '../../service/datastore.dart';
import '../../service/github_service.dart';

// Filenames which are not actually tests.
const List<String> kNotActuallyATest = <String>[
  'packages/flutter/lib/src/gestures/hit_test.dart',
];

/// List of repos that require check for tests.
Set<RepositorySlug> kNeedsTests = <RepositorySlug>{
  Config.engineSlug,
  Config.flutterSlug,
  Config.packagesSlug,
};

// Extentions for files that use // for single line comments.
// See [_allChangesAreCodeComments] for more.
@visibleForTesting
const Set<String> knownCommentCodeExtensions = <String>{
  'cc',
  'cpp',
  'dart',
  'gradle',
  'groovy',
  'java',
  'kt',
  'm',
  'mm',
  'swift',
};

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
@immutable
class GithubWebhookSubscription extends SubscriptionHandler {
  /// Creates a subscription for processing GitHub webhooks.
  const GithubWebhookSubscription({
    required super.cache,
    required super.config,
    required this.scheduler,
    required this.gerritService,
    required this.commitService,
    this.datastoreProvider = DatastoreService.defaultProvider,
    required this.fusionTester,
    super.authProvider,
    // Gets the initial github events from this sub after the webhook uploads them.
  }) : super(subscriptionName: 'github-webhooks-sub');

  /// Cocoon scheduler to trigger tasks against changes from GitHub.
  final Scheduler scheduler;

  /// To verify whether a commit was mirrored to GoB.
  final GerritService gerritService;

  /// Used to handle push events and create commits based on those events.
  final CommitService commitService;

  final DatastoreServiceProvider datastoreProvider;

  final FusionTester fusionTester;

  @override
  Future<Body> post() async {
    if (message.data == null || message.data!.isEmpty) {
      log.warning('GitHub webhook message was empty. No-oping');
      return Body.empty;
    }

    final pb.GithubWebhookMessage webhook = pb.GithubWebhookMessage.fromJson(message.data!);

    log.info('Processing ${webhook.event}');
    log.finest(webhook.payload);
    switch (webhook.event) {
      case 'pull_request':
        await _handlePullRequest(webhook.payload);
        break;
      case 'merge_group':
        await _handleMergeGroup(webhook.payload);
        break;
      case 'check_run':
        final Map<String, dynamic> event = jsonDecode(webhook.payload) as Map<String, dynamic>;
        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(event);
        if (await scheduler.processCheckRun(checkRunEvent) == false) {
          throw InternalServerError('Failed to process check_run event. checkRunEvent: $checkRunEvent');
        }
        break;
      case 'push':
        final Map<String, dynamic> event = jsonDecode(webhook.payload) as Map<String, dynamic>;
        final String branch = event['ref'].split('/')[2]; // Eg: refs/heads/beta would return beta.
        final String repository = event['repository']['name'];
        // If the branch is beta/stable, then a commit wasn't created through a PR,
        // meaning the commit needs to be added to the datastore here instead.
        if (repository == 'flutter' && (branch == 'stable' || branch == 'beta')) {
          await commitService.handlePushGithubRequest(event);
        }
        break;
      case 'create':
        final CreateEvent createEvent = CreateEvent.fromJson(json.decode(webhook.payload) as Map<String, dynamic>);
        final RegExp candidateBranchRegex = RegExp(r'flutter-\d+\.\d+-candidate\.\d+');
        // Create a commit object for candidate branches in the datastore so
        // dart-internal builds that are triggered by the initial branch
        // creation have an associated commit.
        if (candidateBranchRegex.hasMatch(createEvent.ref!)) {
          log.fine('Branch ${createEvent.ref} is a candidate branch, creating new commit in the datastore');
          await commitService.handleCreateGithubRequest(createEvent);
        }
    }

    return Body.empty;
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
  Future<void> _handlePullRequest(
    String rawRequest,
  ) async {
    final PullRequestEvent? pullRequestEvent = await _getPullRequestEvent(rawRequest);
    if (pullRequestEvent == null) {
      throw const BadRequestException('Expected pull request event.');
    }
    final String? eventAction = pullRequestEvent.action;
    final PullRequest pr = pullRequestEvent.pullRequest!;

    // See the API reference:
    // https://developer.github.com/v3/activity/events/types/#pullrequestevent
    // which unfortunately is a bit light on explanations.
    log.fine('Processing $eventAction for ${pr.htmlUrl}');
    switch (eventAction) {
      case 'closed':
        await _processPullRequestClosed(pullRequestEvent);
        break;
      case 'edited':
        await _checkForTests(pullRequestEvent);
        // In the event of the base ref changing we want to start new checks.
        if (pullRequestEvent.changes != null && pullRequestEvent.changes!.base != null) {
          await _scheduleIfMergeable(pullRequestEvent);
        }
        break;
      case 'opened':
      case 'reopened':
        // These cases should trigger LUCI jobs. The closed event should happen
        // before these which should cancel all in progress checks.
        await _checkForTests(pullRequestEvent);
        await _scheduleIfMergeable(pullRequestEvent);
        await _tryReleaseApproval(pullRequestEvent);
        break;
      case 'labeled':
        break;
      case 'synchronize':
        // This indicates the PR has new commits. We need to cancel old jobs
        // and schedule new ones.
        await _scheduleIfMergeable(pullRequestEvent);
        break;
      case 'dequeued':
        await _respondToPullRequestDequeued(pullRequestEvent);
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
  Future<void> _handleMergeGroup(String rawRequest) async {
    final request = json.decode(rawRequest);

    if (request is! Map<String, Object?>) {
      throw BadRequestException('Malformed merge_group request:\n$rawRequest');
    }

    final mergeGroupEvent = MergeGroupEvent.fromJson(request);
    final MergeGroupEvent(:mergeGroup, :action) = mergeGroupEvent;
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
          throw InternalServerError(
            '$slug/$headSha was not found on GoB. Failing so this event can be retried',
          );
        }
        log.info('$slug/$headSha was found on GoB mirror. Scheduling merge group tasks');
        await scheduler.triggerMergeGroupTargets(mergeGroupEvent: mergeGroupEvent);

      // A merge group was deleted. This can happen when a PR is pulled from the
      // merge queue. All CI jobs pertaining to this merge group should be
      // stopped to save CI resources, as Github will no longer merge this group
      // into the main branch.
      case 'destroyed':
        log.info('Merge group destroyed for $slug/$headSha');
        await scheduler.cancelMergeGroupTargets(headSha: headSha);
    }
  }

  Future<bool> _commitExistsInGob(PullRequest pr) async {
    final RepositorySlug slug = pr.base!.repo!.slug();
    final String sha = pr.mergeCommitSha!;
    return _shaExistsInGob(slug, sha);
  }

  Future<bool> _shaExistsInGob(RepositorySlug slug, String sha) async {
    final GerritCommit? gobCommit = await gerritService.findMirroredCommit(slug, sha);
    return gobCommit != null;
  }

  /// Responds to the "dequeued" pull request event.
  ///
  /// See also: https://docs.github.com/en/webhooks/webhook-events-and-payloads?actionType=dequeued#pull_request
  Future<void> _respondToPullRequestDequeued(
    PullRequestEvent pullRequestEvent,
  ) async {
    final PullRequest pr = pullRequestEvent.pullRequest!;
    final RepositorySlug slug = pullRequestEvent.repository!.slug();
    final GithubService githubService = await config.createGithubService(slug);

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
    final bool hasAutosubmitLabel = pr.labels?.any((label) => label.name == Config.kAutosubmitLabel) ?? false;
    if (hasAutosubmitLabel) {
      await githubService.removeLabel(slug, pr.number!, Config.kAutosubmitLabel);
    }
  }

  /// This method assumes that jobs should be cancelled if they are already
  /// runnning.
  Future<void> _scheduleIfMergeable(
    PullRequestEvent pullRequestEvent,
  ) async {
    final PullRequest pr = pullRequestEvent.pullRequest!;
    final RepositorySlug slug = pullRequestEvent.repository!.slug();

    log.info(
      'Scheduling tasks if mergeable(${pr.mergeable}): owner=${slug.owner} repo=${slug.name} and pr=${pr.number}',
    );

    // The mergeable flag may be null. False indicates there's a merge conflict,
    // null indicates unknown. Err on the side of allowing the job to run.
    if (pr.mergeable == false) {
      final RepositorySlug slug = pullRequestEvent.repository!.slug();
      final GitHub gitHubClient = await config.createGitHubClient(pullRequest: pr);
      final String body = config.mergeConflictPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
      return;
    }

    await scheduler.triggerPresubmitTargets(pullRequest: pr);
  }

  /// Release tooling generates cherrypick pull requests that should be granted an approval.
  Future<void> _tryReleaseApproval(
    PullRequestEvent pullRequestEvent,
  ) async {
    final PullRequest pr = pullRequestEvent.pullRequest!;
    final RepositorySlug slug = pullRequestEvent.repository!.slug();

    final String defaultBranch = Config.defaultBranch(slug);
    final String? branch = pr.base?.ref;
    if (branch == null || branch.contains(defaultBranch)) {
      // This isn't a release branch PR
      return;
    }

    final List<String> releaseAccounts = await config.releaseAccounts;
    if (releaseAccounts.contains(pr.user?.login) == false) {
      // The author isn't in the list of release accounts, do nothing
      return;
    }

    final GitHub gitHubClient = config.createGitHubClientWithToken(await config.githubOAuthToken);
    final CreatePullRequestReview review = CreatePullRequestReview(slug.owner, slug.name, pr.number!, 'APPROVE');
    await gitHubClient.pullRequests.createReview(slug, review);
  }

  Future<void> _processPullRequestClosed(PullRequestEvent pullRequestEvent) async {
    final PullRequest pr = pullRequestEvent.pullRequest!;

    // Cancel any outstanding presubmit jobs. They are useless after the PR is
    // closed. If the PR was merged, then the post-submit results will determine
    // what needs to be done about this PR (maybe it lands, or maybe it will be
    // reverted). If the PR was just closed and abandoned, well, that means we
    // don't care about it any more.
    await scheduler.cancelPreSubmitTargets(
      pullRequest: pr,
      reason: (!pr.merged!) ? 'Pull request closed' : 'Pull request merged',
    );

    if (pr.merged!) {
      log.fine('Pull request ${pr.number} was closed and merged.');

      // To avoid polluting the repo with temporary revert branches, delete the
      // branch after the reverted PR is merged.
      //
      // This can be done no ealier than the event declaring the PR both
      // 'closed' and merged, because:
      //
      // * If the branch is deleted before the PR reaches 'closed', then GitHub
      //   will force-close the PR because the branch is the source of all the
      //   code changes in the PR. In a previous iteration, Cocoon used to
      //   delete the branch immediately after merging it. However, with merge
      //   queues a PR is not merged by Cocoon anymore. It stays open while in
      //   the merge queue. Deleting the branch while in the queue would close
      //   the PR and not merge it.
      // * If a PR is closed but not merged, the author may still want to reopen
      //   the PR. That would not be possible if the source branch was deleted.
      final isRevertPullRequest = pr.labels?.any((label) => label.name == Config.revertOfLabel) == true;
      if (isRevertPullRequest) {
        log.info('Revert merged successfully, deleting branch ${pr.head!.ref!}');
        final slug = pullRequestEvent.repository!.slug();
        final githubService = await config.createGithubService(slug);
        await githubService.deleteBranch(slug, pr.head!.ref!);
      }

      if (await _commitExistsInGob(pr)) {
        log.fine('Merged commit was found on GoB mirror. Scheduling postsubmit tasks...');
        return scheduler.addPullRequest(pr);
      }
      throw InternalServerError(
        '${pr.mergeCommitSha!} was not found on GoB. Failing so this event can be retried...',
      );
    }
  }

  Future<void> _checkForTests(PullRequestEvent pullRequestEvent) async {
    final PullRequest pr = pullRequestEvent.pullRequest!;
    final String? eventAction = pullRequestEvent.action;
    final RepositorySlug slug = pr.base!.repo!.slug();
    final bool isTipOfTree = pr.base!.ref == Config.defaultBranch(slug);
    final GitHub gitHubClient = await config.createGitHubClient(pullRequest: pr);
    await _validateRefs(gitHubClient, pr);
    if (kNeedsTests.contains(slug) && isTipOfTree) {
      switch (slug.name) {
        case 'flaux':
        case 'flutter':
          final bool isFusion = await fusionTester.isFusionBasedRef(slug, pr.head!.sha!);
          final files = await gitHubClient.pullRequests.listFiles(slug, pr.number!).toList();
          await _applyFrameworkRepoLabels(gitHubClient, eventAction, pr, isFusion: isFusion, files: files);
          if (isFusion) {
            await _applyEngineRepoLabels(gitHubClient, eventAction, pr, files: files);
          }
        case 'engine':
          final files = await gitHubClient.pullRequests.listFiles(slug, pr.number!).toList();
          return _applyEngineRepoLabels(gitHubClient, eventAction, pr, files: files);
        case 'packages':
          return _applyPackageTestChecks(gitHubClient, eventAction, pr);
      }
    }
  }

  Future<void> _applyFrameworkRepoLabels(
    GitHub gitHubClient,
    String? eventAction,
    PullRequest pr, {
    bool isFusion = false,
    List<PullRequestFile>? files,
  }) async {
    if (pr.user!.login == 'engine-flutter-autoroll') {
      return;
    }

    final RepositorySlug slug = pr.base!.repo!.slug();
    log.info(
      'Applying framework repo labels for: owner=${slug.owner} repo=${slug.name} isFusion=$isFusion and pr=${pr.number}',
    );

    files ??= await gitHubClient.pullRequests.listFiles(slug, pr.number!).toList();

    final Set<String> labels = <String>{};
    bool hasTests = false;
    bool needsTests = false;

    int frameworkFiles = 0;

    for (var file in files) {
      final String filename = file.filename!;

      if (!_isFusionEnginePath(filename)) {
        frameworkFiles++;
      }

      if (_fileContainsAddedCode(file) &&
          !_isTestExempt(filename) &&
          !filename.startsWith('dev/bots/') &&
          !filename.endsWith('.gitignore')) {
        needsTests = !_allChangesAreCodeComments(file);
      }

      // Check to see if tests were submitted with this PR.
      if (_isAFrameworkTest(filename)) {
        hasTests = true;
      }
    }

    if (frameworkFiles == 0) {
      // a fusion / engine only change.
      return;
    }

    if (pr.user!.login == 'fluttergithubbot') {
      needsTests = false;
      labels.addAll(<String>['c: tech-debt', 'c: flake']);
    }

    if (labels.isNotEmpty) {
      await gitHubClient.issues.addLabelsToIssue(slug, pr.number!, labels.toList());
    }

    // We do not need to add test labels if this is an auto roller author.
    if (config.rollerAccounts.contains(pr.user!.login)) {
      return;
    }

    if (!hasTests && needsTests && !pr.draft! && !_isReleaseBranch(pr)) {
      final String body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
    }
  }

  bool _isAFrameworkTest(String filename) {
    if (kNotActuallyATest.any(filename.endsWith)) {
      return false;
    }
    // Check for Objective-C tests which end in either "Tests.m" or "Test.m"
    // in the "dev" directory.
    final RegExp objectiveCTestRegex = RegExp(r'.*dev\/.*Test[s]?\.m$');
    return filename.endsWith('_test.dart') ||
        filename.endsWith('.expect') ||
        filename.contains('test_fixes') ||
        // Include updates to test utilities or test data
        filename.contains('packages/flutter_tools/test/') ||
        filename.startsWith('dev/bots/analyze.dart') ||
        filename.startsWith('dev/bots/test.dart') ||
        filename.startsWith('dev/devicelab/bin/tasks') ||
        filename.startsWith('dev/devicelab/lib/tasks') ||
        filename.startsWith('dev/benchmarks') ||
        objectiveCTestRegex.hasMatch(filename);
  }

  /// Returns true if changes to [filename] are exempt from the testing
  /// requirement, across repositories.
  bool _isTestExempt(String filename, {String engineBasePath = ''}) {
    final bool isBuildPythonScript = (filename.startsWith('${engineBasePath}sky/tools') && filename.endsWith('.py'));
    return filename.contains('.ci.yaml') ||
        filename.endsWith('analysis_options.yaml') ||
        filename.endsWith('AUTHORS') ||
        filename.endsWith('CODEOWNERS') ||
        filename.endsWith('TESTOWNERS') ||
        filename.endsWith('pubspec.yaml') ||
        filename.endsWith('pubspec.yaml.tmpl') ||
        // Exempt categories.
        filename.contains('.github/') ||
        filename.endsWith('.md') ||
        // Exempt paths.
        filename.startsWith('dev/devicelab/lib/versions/gallery.dart') ||
        filename.startsWith('dev/integration_tests/') ||
        filename.startsWith('docs/') ||
        filename.startsWith('${engineBasePath}docs/') ||
        // ↓↓↓ Begin engine specific paths ↓↓↓
        filename == 'DEPS' || // note: in monorepo; DEPS is still at the root.
        isBuildPythonScript ||
        filename.startsWith('${engineBasePath}impeller/fixtures/') ||
        filename.startsWith('${engineBasePath}impeller/golden_tests/') ||
        filename.startsWith('${engineBasePath}impeller/playground/') ||
        filename.startsWith('${engineBasePath}shell/platform/embedder/tests/') ||
        filename.startsWith('${engineBasePath}shell/platform/embedder/fixtures/') ||
        filename.startsWith('${engineBasePath}testing/') ||
        filename.startsWith('${engineBasePath}tools/clangd_check/');
  }

  bool _isFusionEnginePath(String path) => (path.startsWith('engine/') || path == 'DEPS');

  Future<void> _applyEngineRepoLabels(
    GitHub gitHubClient,
    String? eventAction,
    PullRequest pr, {
    List<PullRequestFile>? files,
  }) async {
    // Do not apply the test labels for the autoroller accounts.
    if (pr.user!.login == 'skia-flutter-autoroll') {
      return;
    }

    final RepositorySlug slug = pr.base!.repo!.slug();
    bool hasTests = false;
    bool needsTests = false;

    // If engine labels are being applied to the flutterSlug - we're in a fusion repo.
    final bool isFusion = slug == Config.flutterSlug;
    final engineBasePath = isFusion ? 'engine/src/flutter/' : '';

    int engineFiles = 0;

    files ??= await gitHubClient.pullRequests.listFiles(slug, pr.number!).toList();
    for (var file in files) {
      final String path = file.filename!;
      if (isFusion && _isFusionEnginePath(path)) {
        engineFiles++;
      }

      if (_fileContainsAddedCode(file) &&
          !_isTestExempt(path, engineBasePath: engineBasePath) &&
          // License goldens are auto-generated.
          !path.startsWith('${engineBasePath}ci/licenses_golden/') &&
          // Build configuration files tell CI what to run.
          !path.startsWith('${engineBasePath}ci/builders/') &&
          // Build files don't need unit tests.
          !path.endsWith('$engineBasePath.gn') &&
          !path.endsWith('$engineBasePath.gni')) {
        needsTests = !_allChangesAreCodeComments(file);
      }

      if (_isAnEngineTest(path)) {
        hasTests = true;
      }
    }

    if (isFusion && engineFiles == 0) {
      // framework only change
      return;
    }

    // We do not need to add test labels if this is an auto roller author.
    if (config.rollerAccounts.contains(pr.user!.login)) {
      return;
    }

    if (!hasTests && needsTests && !pr.draft! && !_isReleaseBranch(pr)) {
      final String body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
    }
  }

  bool _isAnEngineTest(String filename) {
    final RegExp engineTestRegExp = RegExp(r'(tests?|benchmarks?)\.(dart|java|mm|m|cc|sh|py)$');
    return filename.contains('IosBenchmarks') ||
        filename.contains('IosUnitTests') ||
        filename.contains('scenario_app') ||
        engineTestRegExp.hasMatch(filename.toLowerCase());
  }

  bool _fileContainsAddedCode(PullRequestFile file) {
    // When null, do not assume 0 lines have been added.
    final int linesAdded = file.additionsCount ?? 1;
    final int linesDeleted = file.deletionsCount ?? 0;
    final int linesTotal = file.changesCount ?? linesDeleted + linesAdded;
    return linesAdded > 0 || linesDeleted != linesTotal;
  }

  // Runs automated test checks for both flutter/packages.
  Future<void> _applyPackageTestChecks(GitHub gitHubClient, String? eventAction, PullRequest pr) async {
    final RepositorySlug slug = pr.base!.repo!.slug();
    final Stream<PullRequestFile> files = gitHubClient.pullRequests.listFiles(slug, pr.number!);
    bool hasTests = false;
    bool needsTests = false;

    await for (PullRequestFile file in files) {
      final String filename = file.filename!;

      if (_fileContainsAddedCode(file) &&
          !_isTestExempt(filename) &&
          !filename.contains('.ci/') &&
          // Custom package-specific test runners. These do not count as tests
          // for the purposes of testing a change that otherwise needs tests,
          // but since they are the driver for tests they don't need test
          // coverage.
          !filename.endsWith('tool/run_tests.dart') &&
          !filename.endsWith('run_tests.sh')) {
        needsTests = !_allChangesAreCodeComments(file);
      }
      // See https://github.com/flutter/flutter/blob/master/docs/ecosystem/testing/Plugin-Tests.md for discussion
      // of various plugin test types and locations.
      if (filename.endsWith('_test.dart') ||
          // Native iOS/macOS tests.
          filename.contains('RunnerTests/') ||
          filename.contains('RunnerUITests/') ||
          filename.contains('darwin/Tests/') ||
          // Native Android tests.
          filename.contains('android/src/test/') ||
          filename.contains('androidTest/') ||
          // Native Linux tests.
          filename.endsWith('_test.cc') ||
          // Native Windows tests.
          filename.endsWith('_test.cpp') ||
          // Pigeon native tests.
          filename.contains('/platform_tests/') ||
          // Test files in package-specific test folders.
          filename.contains('go_router/test_fixes/') ||
          filename.contains('go_router_builder/test_inputs/')) {
        hasTests = true;
      }
    }

    // We do not need to add test labels if this is an auto roller author.
    if (config.rollerAccounts.contains(pr.user!.login)) {
      return;
    }

    if (!hasTests && needsTests && !pr.draft! && !_isReleaseBranch(pr)) {
      final String body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
    }
  }

  /// Validate the base and head refs of the PR.
  Future<void> _validateRefs(
    GitHub gitHubClient,
    PullRequest pr,
  ) async {
    final RepositorySlug slug = pr.base!.repo!.slug();
    String body;
    const List<String> releaseChannels = <String>[
      'stable',
      'beta',
      'dev',
    ];
    // Close PRs that use a release branch as a source.
    if (releaseChannels.contains(pr.head!.ref)) {
      body = config.wrongHeadBranchPullRequestMessage(pr.head!.ref!);
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.pullRequests.edit(
          slug,
          pr.number!,
          state: 'closed',
        );
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
      return;
    }
    final String defaultBranchName = Config.defaultBranch(pr.base!.repo!.slug());
    final String baseName = pr.base!.ref!;
    if (baseName == defaultBranchName) {
      return;
    }
    if (_isReleaseBranch(pr)) {
      body = config.releaseBranchPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
      return;
    }

    // For repos migrated to main, close PRs opened against master.
    final bool isMaster = pr.base?.ref == 'master';
    final bool isMigrated = defaultBranchName == 'main';
    // PRs should never be open to "beta" or "stable."
    final bool isReleaseChannelBranch = releaseChannels.contains(pr.base?.ref);
    if ((isMaster && isMigrated) || isReleaseChannelBranch) {
      body = _getWrongBaseComment(base: baseName, defaultBranch: defaultBranchName);
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.pullRequests.edit(
          slug,
          pr.number!,
          base: Config.defaultBranch(slug),
        );
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
    }
  }

  bool _isReleaseBranch(PullRequest pr) {
    final String defaultBranchName = Config.defaultBranch(pr.base!.repo!.slug());
    final String baseName = pr.base!.ref!;

    if (baseName == defaultBranchName) {
      return false;
    }
    // Check if branch name confroms to the format flutter-x.x-candidate.x,
    // A pr with conforming branch name is likely to be intended
    // for a release branch, whereas a pr with non conforming name is likely
    // caused by user misoperations, in which case bot
    // will suggest open pull request against default branch instead.
    final RegExp candidateTest = RegExp(r'flutter-\d+\.\d+-candidate\.\d+');
    if (candidateTest.hasMatch(baseName) && candidateTest.hasMatch(pr.head!.ref!)) {
      return true;
    }
    return false;
  }

  Future<bool> _alreadyCommented(
    GitHub gitHubClient,
    PullRequest pr,
    String message,
  ) async {
    final Stream<IssueComment> comments = gitHubClient.issues.listCommentsByIssue(pr.base!.repo!.slug(), pr.number!);
    await for (IssueComment comment in comments) {
      if (comment.body != null && comment.body!.contains(message)) {
        return true;
      }
    }
    return false;
  }

  String _getWrongBaseComment({
    required String base,
    required String defaultBranch,
  }) {
    final String messageTemplate = config.wrongBaseBranchPullRequestMessage;
    return messageTemplate.replaceAll('{{target_branch}}', base).replaceAll('{{default_branch}}', defaultBranch);
  }

  Future<PullRequestEvent?> _getPullRequestEvent(String request) async {
    try {
      return PullRequestEvent.fromJson(json.decode(request) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  /// Returns true if the changes to [file] are all code comments.
  ///
  /// If that cannot be determined with confidence, returns false. False
  /// negatives (e.g., for /* */-style multi-line comments) should be expected.
  bool _allChangesAreCodeComments(PullRequestFile file) {
    final int? linesAdded = file.additionsCount;
    final int? linesDeleted = file.deletionsCount;
    final String? patch = file.patch;
    // If information is missing, err or the side of assuming it's a non-comment
    // change.
    if (linesAdded == null || linesDeleted == null || patch == null) {
      return false;
    }

    final String filename = file.filename!;
    final String? extension = filename.contains('.') ? filename.split('.').last.toLowerCase() : null;
    if (extension == null || !knownCommentCodeExtensions.contains(extension)) {
      return false;
    }

    // Only handles single-line comments; identifying multi-line comments
    // would require the full file and non-trivial parsing. Also doesn't handle
    // end-of-line comments (e.g., "int x = 0; // Info about x").
    final RegExp commentRegex = RegExp(r'^[+-]\s*//');
    final RegExp onlyWhitespaceRegex = RegExp(r'^[+-]\s*$');
    for (String line in patch.split('\n')) {
      if (!line.startsWith('+') && !line.startsWith('-')) {
        continue;
      }

      if (onlyWhitespaceRegex.hasMatch(line)) {
        // whitespace only changes don't require tests
        continue;
      }

      if (!commentRegex.hasMatch(line)) {
        return false;
      }
    }
    return true;
  }
}
