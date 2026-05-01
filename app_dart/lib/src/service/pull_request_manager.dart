// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_common/is_release_branch.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/firestore/v1.dart' hide Value;

import '../model/firestore/pr_check_runs.dart';
import '../model/firestore/pull_request_state.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/response.dart';
import 'cache_service.dart';
import 'config.dart';
import 'firestore.dart';
import 'gerrit_service.dart';
import 'github_service.dart';
import 'scheduler.dart';
import 'scheduler/process_check_run_result.dart';

// Filenames which are not actually tests.
const List<String> kNotActuallyATest = <String>[
  'packages/flutter/lib/src/gestures/hit_test.dart',
];

/// List of repos that require check for tests.
Set<RepositorySlug> kNeedsTests = <RepositorySlug>{
  Config.flutterSlug,
  Config.packagesSlug,
};

// Extentions for files that use // for single line comments.
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

/// Manages the state and event queue for a single Pull Request.
class PullRequestManager {
  final RepositorySlug slug;
  final int prNumber;
  final FirestoreService firestore;
  final Config config;
  final Scheduler scheduler;
  final GerritService gerritService;
  final PullRequestLabelProcessorProvider pullRequestLabelProcessorProvider;

  final bool _isPrivileged;
  String _latestSha;
  String? _scheduledSha;
  bool _isDirty = false;

  PullRequestManager._({
    required this.slug,
    required this.prNumber,
    required this.firestore,
    required this.config,
    required this.scheduler,
    required this.gerritService,
    required this.pullRequestLabelProcessorProvider,
    required bool isPrivileged,
    required String latestSha,
    String? scheduledSha,
  }) : _isPrivileged = isPrivileged,
       _latestSha = latestSha,
       _scheduledSha = scheduledSha;

  /// Runs an action with a distributed lock on the pull request.
  static Future<T> _runWithLock<T>({
    required PullRequestEvent event,
    required CacheService cache,
    required Future<T> Function() action,
  }) async {
    final pr = event.pullRequest!;
    final slug = event.repository!.slug();
    final prNumber = pr.number!;
    final lockKey = 'pr_lock_${slug.owner}_${slug.name}_$prNumber';
    final lockValue = Uint8List.fromList('l'.codeUnits);

    // Attempt to acquire lock
    final existingLock = await cache.getOrCreate(
      'pr_locks',
      lockKey,
      createFn: null,
    );
    if (existingLock != null) {
      throw const ServiceUnavailable('PR is locked by another instance');
    }
    await cache.set(
      'pr_locks',
      lockKey,
      lockValue,
      ttl: const Duration(minutes: 5),
    );

    try {
      return await action();
    } finally {
      await cache.purge('pr_locks', lockKey);
    }
  }

  static Future<void> handleOpened(
    PullRequestEvent event,
    PullRequestEventContext context,
  ) async {
    await _runWithLock(
      event: event,
      cache: context.cache,
      action: () async {
        final manager = await PullRequestManager._create(
          slug: event.repository!.slug(),
          prNumber: event.pullRequest!.number!,
          firestore: context.firestore,
          config: context.config,
          scheduler: context.scheduler,
          gerritService: context.gerritService,
          pullRequestLabelProcessorProvider:
              context.pullRequestLabelProcessorProvider,
          event: event,
        );
        await manager._handleOpened(event);
        await manager.persist();
      },
    );
  }

  static Future<void> handleSynchronize(
    PullRequestEvent event,
    PullRequestEventContext context,
  ) async {
    await _runWithLock(
      event: event,
      cache: context.cache,
      action: () async {
        final manager = await PullRequestManager._create(
          slug: event.repository!.slug(),
          prNumber: event.pullRequest!.number!,
          firestore: context.firestore,
          config: context.config,
          scheduler: context.scheduler,
          gerritService: context.gerritService,
          pullRequestLabelProcessorProvider:
              context.pullRequestLabelProcessorProvider,
          event: event,
        );
        await manager._handleSynchronize(event);
        await manager.persist();
      },
    );
  }

  static Future<void> handleEdited(
    PullRequestEvent event,
    PullRequestEventContext context,
  ) async {
    await _runWithLock(
      event: event,
      cache: context.cache,
      action: () async {
        final manager = await PullRequestManager._create(
          slug: event.repository!.slug(),
          prNumber: event.pullRequest!.number!,
          firestore: context.firestore,
          config: context.config,
          scheduler: context.scheduler,
          gerritService: context.gerritService,
          pullRequestLabelProcessorProvider:
              context.pullRequestLabelProcessorProvider,
          event: event,
        );
        await manager._handleEdited(event);
        await manager.persist();
      },
    );
  }

  static Future<void> handleReopened(
    PullRequestEvent event,
    PullRequestEventContext context,
  ) async {
    await _runWithLock(
      event: event,
      cache: context.cache,
      action: () async {
        final manager = await PullRequestManager._create(
          slug: event.repository!.slug(),
          prNumber: event.pullRequest!.number!,
          firestore: context.firestore,
          config: context.config,
          scheduler: context.scheduler,
          gerritService: context.gerritService,
          pullRequestLabelProcessorProvider:
              context.pullRequestLabelProcessorProvider,
          event: event,
        );
        await manager._handleReopened(event);
        await manager.persist();
      },
    );
  }

  static Future<void> handleLabeled(
    PullRequestEvent event,
    PullRequestEventContext context,
    String? labelName,
    int? labelId,
  ) async {
    await _runWithLock(
      event: event,
      cache: context.cache,
      action: () async {
        final manager = await PullRequestManager._create(
          slug: event.repository!.slug(),
          prNumber: event.pullRequest!.number!,
          firestore: context.firestore,
          config: context.config,
          scheduler: context.scheduler,
          gerritService: context.gerritService,
          pullRequestLabelProcessorProvider:
              context.pullRequestLabelProcessorProvider,
          event: event,
        );
        await manager._handleLabeled(event, labelName, labelId);
        await manager.persist();
      },
    );
  }

  static Future<Response> handleClosed(
    PullRequestEvent event,
    PullRequestEventContext context,
    Future<ProcessCheckRunResult> Function(PullRequestEvent) processClosedFn,
  ) async {
    return await _runWithLock<Response>(
      event: event,
      cache: context.cache,
      action: () async {
        final result = await processClosedFn(event);
        return result.toResponse();
      },
    );
  }

  /// Creates and hydrates a [PullRequestManager] instance.
  static Future<PullRequestManager> _create({
    required RepositorySlug slug,
    required int prNumber,
    required FirestoreService firestore,
    required Config config,
    required Scheduler scheduler,
    required GerritService gerritService,
    required PullRequestLabelProcessorProvider
    pullRequestLabelProcessorProvider,
    required PullRequestEvent event,
  }) async {
    final documentId = PullRequestState.getDocumentId(slug, prNumber);
    final name =
        '$kDocumentParent/${PullRequestState.kCollectionId}/$documentId';

    bool isPrivileged;
    String latestSha;
    String? scheduledSha;

    try {
      final doc = await firestore.getDocument(name);
      final state = PullRequestState.fromDocument(doc);
      isPrivileged = state.isPrivileged ?? false;
      latestSha = state.latestSha ?? event.pullRequest!.head!.sha!;
      scheduledSha = state.scheduledSha;
      log.info(
        'Hydrated PullRequestManager for $slug/$prNumber: isPrivileged=$isPrivileged, latestSha=$latestSha, scheduledSha=$scheduledSha',
      );
    } on DetailedApiRequestError catch (e) {
      if (e.status != HttpStatus.notFound) {
        rethrow;
      }

      // Document not found, initialize as new
      final pr = event.pullRequest!;
      final author = pr.user!.login!;
      final githubService = await config.createGithubService(slug);
      final isRoller = config.rollerAccounts.contains(author);
      final isFlutterHacker = await githubService.isTeamMember(
        'flutter-hackers',
        author,
        slug.owner,
      );
      isPrivileged = isRoller || isFlutterHacker;
      latestSha = pr.head!.sha!;

      // Persist initial state using the specific document ID!
      final state = PullRequestState()
        ..slug = slug
        ..number = prNumber
        ..isPrivileged = isPrivileged
        ..latestSha = latestSha;

      final document = Document(fields: state.fields);
      await firestore.createDocument(
        document,
        collectionId: PullRequestState.kCollectionId,
        documentId: documentId,
      );
      log.info('Created initial PullRequestState for $slug/$prNumber');
    }

    return PullRequestManager._(
      slug: slug,
      prNumber: prNumber,
      firestore: firestore,
      config: config,
      scheduler: scheduler,
      gerritService: gerritService,
      pullRequestLabelProcessorProvider: pullRequestLabelProcessorProvider,
      isPrivileged: isPrivileged,
      latestSha: latestSha,
      scheduledSha: scheduledSha,
    );
  }

  /// Persists the current state to Firestore if modified.
  Future<void> persist() async {
    if (!_isDirty) {
      return;
    }

    final documentId = PullRequestState.getDocumentId(slug, prNumber);
    final name =
        '$kDocumentParent/${PullRequestState.kCollectionId}/$documentId';

    final state = PullRequestState()
      ..slug = slug
      ..number = prNumber
      ..isPrivileged = _isPrivileged
      ..latestSha = latestSha
      ..scheduledSha = _scheduledSha;

    final document = Document(name: name, fields: state.fields);

    await firestore.writeViaTransaction(documentsToWrites([document]));
    log.info('Persisted PullRequestState for $slug/$prNumber');
    _isDirty = false;
  }

  /// The latest SHA that we have processed for this PR.
  String get latestSha => _latestSha;
  set latestSha(String value) {
    if (_latestSha != value) {
      _latestSha = value;
      _isDirty = true;
    }
  }

  /// The SHA for which we have scheduled presubmits.
  String? get scheduledSha => _scheduledSha;
  set scheduledSha(String? value) {
    if (_scheduledSha != value) {
      _scheduledSha = value;
      _isDirty = true;
    }
  }

  /// Handles PR opened event.
  Future<void> _handleOpened(PullRequestEvent event) async {
    final pr = event.pullRequest!;
    final sha = pr.head!.sha!;
    latestSha = sha; // Update latest SHA.

    if (!pr.draft! && _isPrivileged) {
      final gitHubClient = await config.createGitHubClient(pullRequest: pr);
      await gitHubClient.issues.addLabelsToIssue(slug, pr.number!, ['CICD']);
      log.debug('Added CICD label to PR $pr.number');
      await _scheduleIfMergeable(event);
    } else {
      await scheduler.createAwaitingCicdLabelCheckRun(slug, sha);
    }

    await checkForTests(event);
    await _tryReleaseApproval(event);
  }

  /// Handles PR synchronize event.
  Future<void> _handleSynchronize(PullRequestEvent event) async {
    final pr = event.pullRequest!;
    final sha = pr.head!.sha!;
    latestSha = sha; // Update latest SHA.

    final hasLabel =
        pr.labels?.any((IssueLabel l) => l.name == Config.kCicdLabel) ?? false;
    final isPrivilegedUser = _isPrivileged;

    if (isPrivilegedUser) {
      if (hasLabel) {
        await _scheduleIfMergeable(event);
      } else {
        await scheduler.createAwaitingCicdLabelCheckRun(slug, sha);
      }
    } else {
      if (hasLabel) {
        final githubService = await config.createGithubService(slug);
        await githubService.removeLabel(slug, pr.number!, Config.kCicdLabel);
        log.debug('Removed CICD label from PR ${pr.number}');
      }
      await scheduler.createAwaitingCicdLabelCheckRun(slug, sha);
    }
  }

  /// Handles PR edited event.
  Future<void> _handleEdited(PullRequestEvent event) async {
    await checkForTests(event);
  }

  /// Handles PR reopened event.
  Future<void> _handleReopened(PullRequestEvent event) async {
    final pr = event.pullRequest!;
    await _warnThatANewCommitIsNeeded(event);
    await _processLabels(pr);
    await _updatePullRequest(pr);
  }

  /// Handles PR labeled event.
  Future<void> _handleLabeled(
    PullRequestEvent event,
    String? labelName,
    int? labelId,
  ) async {
    final pr = event.pullRequest!;
    final sha = pr.head!.sha!;

    if (labelName == Config.kCicdLabel &&
        Config.kCicdLabelIds.contains(labelId)) {
      log.info('new CICD label added - scheduling tests');
      await scheduler.resolveAwaitingCicdLabelCheckRun(slug, sha);
      await _scheduleIfMergeable(event);
    }

    await _processLabels(pr);
    await _updatePullRequest(pr);
  }

  Future<void> checkForTests(PullRequestEvent pullRequestEvent) async {
    final pr = pullRequestEvent.pullRequest!;
    // We do not need to add test labels if this is an auto roller author.
    if (config.rollerAccounts.contains(pr.user!.login)) {
      return;
    }
    final eventAction = pullRequestEvent.action;
    final isTipOfTree = pr.base!.ref == Config.defaultBranch(slug);
    final gitHubClient = await config.createGitHubClient(pullRequest: pr);
    await _validateRefs(gitHubClient, pr);
    if (kNeedsTests.contains(slug) && isTipOfTree) {
      log.info(
        'Applying framework repo labels for: owner=${slug.owner} repo=${slug.name} and pr=${pr.number}',
      );
      switch (slug.name) {
        case 'flutter':
          final isFusion = slug == Config.flutterSlug;
          final files = await gitHubClient.pullRequests
              .listFiles(slug, pr.number!)
              .toList();
          await _applyFrameworkRepoLabels(
            gitHubClient,
            eventAction,
            pr,
            files,
            slug,
          );
          if (isFusion) {
            await _applyEngineRepoLabels(
              gitHubClient,
              eventAction,
              pr,
              files,
              slug,
            );
          }
        case 'packages':
          return _applyPackageTestChecks(gitHubClient, eventAction, pr);
      }
    }
  }

  Future<void> _applyFrameworkRepoLabels(
    GitHub gitHubClient,
    String? eventAction,
    PullRequest pr,
    List<PullRequestFile> files,
    RepositorySlug slug,
  ) async {
    if (pr.user!.login == 'engine-flutter-autoroll') {
      return;
    }

    final labels = <String>{};
    var hasTests = false;
    var needsTests = false;

    var frameworkFiles = 0;

    for (var file in files) {
      final filename = file.filename!;

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
      await gitHubClient.issues.addLabelsToIssue(
        slug,
        pr.number!,
        labels.toList(),
      );
    }

    if (!hasTests &&
        needsTests &&
        !pr.draft! &&
        !_isPrUpdatingReleaseBranch(pr)) {
      final body = config.missingTestsPullRequestMessage;
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
    final objectiveCTestRegex = RegExp(r'.*dev\/.*Test[s]?\.m$');
    return filename.endsWith('_test.dart') ||
        filename.endsWith('.expect') ||
        filename.contains('test_fixes') ||
        // Include updates to test utilities or test data
        filename.contains('packages/flutter_tools/test/') ||
        // Kotlin source tests, used in the Flutter Gradle Plugin.
        filename.startsWith('packages/flutter_tools/gradle/src/test/') ||
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
    final isBuildPythonScript =
        filename.startsWith('${engineBasePath}sky/tools') &&
        filename.endsWith('.py');
    return filename.contains('.ci.yaml') ||
        filename.endsWith('analysis_options.yaml') ||
        filename.endsWith('AUTHORS') ||
        filename.endsWith('CODEOWNERS') ||
        filename.endsWith('TESTOWNERS') ||
        filename.endsWith('pubspec.yaml') ||
        filename.endsWith('pubspec.yaml.tmpl') ||
        // Exempt categories.
        filename.contains('.gemini/') ||
        filename.contains('.github/') ||
        filename.endsWith('.md') ||
        // Exempt paths.
        filename.startsWith('dev/customer_testing/tests.version') ||
        filename.startsWith('dev/devicelab/lib/versions/gallery.dart') ||
        filename.startsWith('dev/integration_tests/') ||
        filename.startsWith('docs/') ||
        filename.startsWith('${engineBasePath}docs/') ||
        filename.endsWith('test/flutter_test_config.dart') ||
        // ↓↓↓ Begin engine specific paths ↓↓↓
        filename == 'DEPS' || // note: in monorepo; DEPS is still at the root.
        isBuildPythonScript ||
        filename.endsWith('.gni') ||
        filename.endsWith('.gn') ||
        filename.startsWith('${engineBasePath}impeller/fixtures/') ||
        filename.startsWith('${engineBasePath}impeller/golden_tests/') ||
        filename.startsWith('${engineBasePath}impeller/playground/') ||
        filename.startsWith(
          '${engineBasePath}shell/platform/embedder/tests/',
        ) ||
        filename.startsWith(
          '${engineBasePath}shell/platform/embedder/fixtures/',
        ) ||
        filename.startsWith('${engineBasePath}testing/') ||
        filename.startsWith('${engineBasePath}tools/clangd_check/');
  }

  bool _isFusionEnginePath(String path) =>
      path.startsWith('engine/') || path == 'DEPS';

  Future<void> _applyEngineRepoLabels(
    GitHub gitHubClient,
    String? eventAction,
    PullRequest pr,
    List<PullRequestFile> files,
    RepositorySlug slug,
  ) async {
    // Do not apply the test labels for the autoroller accounts.
    if (pr.user!.login == 'skia-flutter-autoroll') {
      return;
    }

    var hasTests = false;
    var needsTests = false;

    // If engine labels are being applied to the flutterSlug - we're in a fusion repo.
    final isFusion = slug == Config.flutterSlug;
    final engineBasePath = isFusion ? 'engine/src/flutter/' : '';

    var engineFiles = 0;

    for (var file in files) {
      final path = file.filename!;
      if (isFusion && _isFusionEnginePath(path)) {
        engineFiles++;
      }

      if (_fileContainsAddedCode(file) &&
          !_isTestExempt(path, engineBasePath: engineBasePath) &&
          // License goldens are auto-generated.
          !path.startsWith('${engineBasePath}ci/licenses_golden/') &&
          // Build configuration files tell CI what to run.
          !path.startsWith('${engineBasePath}ci/builders/')) {
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

    if (!hasTests &&
        needsTests &&
        !pr.draft! &&
        !_isPrUpdatingReleaseBranch(pr)) {
      final body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
    }
  }

  bool _isAnEngineTest(String filename) {
    final engineTestRegExp = RegExp(
      r'(tests?|benchmarks?)\.(dart|java|mm|m|cc|sh|py|swift)$',
    );
    return filename.contains('IosBenchmarks') ||
        filename.contains('IosUnitTests') ||
        filename.contains('scenario_app') ||
        engineTestRegExp.hasMatch(filename.toLowerCase());
  }

  bool _fileContainsAddedCode(PullRequestFile file) {
    // When null, do not assume 0 lines have been added.
    final linesAdded = file.additionsCount ?? 1;
    final linesDeleted = file.deletionsCount ?? 0;
    final linesTotal = file.changesCount ?? linesDeleted + linesAdded;
    return linesAdded > 0 || linesDeleted != linesTotal;
  }

  // Runs automated test checks for both flutter/packages.
  Future<void> _applyPackageTestChecks(
    GitHub gitHubClient,
    String? eventAction,
    PullRequest pr,
  ) async {
    final slug = pr.base!.repo!.slug();
    final files = gitHubClient.pullRequests.listFiles(slug, pr.number!);
    var hasTests = false;
    var needsTests = false;

    await for (PullRequestFile file in files) {
      final filename = file.filename!;

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

    if (!hasTests &&
        needsTests &&
        !pr.draft! &&
        !_isPrUpdatingReleaseBranch(pr)) {
      final body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
    }
  }

  /// Validate the base and head refs of the PR.
  Future<void> _validateRefs(GitHub gitHubClient, PullRequest pr) async {
    final slug = pr.base!.repo!.slug();
    String body;
    const releaseChannels = <String>['stable', 'beta', 'dev'];
    // Close PRs that use a release branch as a source.
    if (releaseChannels.contains(pr.head!.ref)) {
      body = config.wrongHeadBranchPullRequestMessage(pr.head!.ref!);
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.pullRequests.edit(slug, pr.number!, state: 'closed');
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
      return;
    }
    final defaultBranchName = Config.defaultBranch(pr.base!.repo!.slug());
    final baseName = pr.base!.ref!;
    if (baseName == defaultBranchName) {
      return;
    }
    if (_isPrUpdatingReleaseBranch(pr)) {
      body = config.releaseBranchPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
      return;
    }

    // For repos migrated to main, close PRs opened against master.
    final isMaster = pr.base?.ref == 'master';
    final isMigrated = defaultBranchName == 'main';
    // PRs should never be open to "beta" or "stable."
    final isReleaseChannelBranch = releaseChannels.contains(pr.base?.ref);
    if ((isMaster && isMigrated) || isReleaseChannelBranch) {
      body = _getWrongBaseComment(
        base: baseName,
        defaultBranch: defaultBranchName,
      );
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

  static bool _isPrUpdatingReleaseBranch(PullRequest pr) {
    return isReleaseCandidateBranch(branchName: pr.base!.ref!);
  }

  Future<bool> _alreadyCommented(
    GitHub gitHubClient,
    PullRequest pr,
    String message,
  ) async {
    final comments = gitHubClient.issues.listCommentsByIssue(
      pr.base!.repo!.slug(),
      pr.number!,
    );
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
    final messageTemplate = config.wrongBaseBranchPullRequestMessage;
    return messageTemplate
        .replaceAll('{{target_branch}}', base)
        .replaceAll('{{default_branch}}', defaultBranch);
  }

  /// Returns true if the changes to [file] are all code comments.
  ///
  /// If that cannot be determined with confidence, returns false. False
  /// negatives (e.g., for /* */-style multi-line comments) should be expected.
  bool _allChangesAreCodeComments(PullRequestFile file) {
    final linesAdded = file.additionsCount;
    final linesDeleted = file.deletionsCount;
    final patch = file.patch;
    // If information is missing, err or the side of assuming it's a non-comment
    // change.
    if (linesAdded == null || linesDeleted == null || patch == null) {
      return false;
    }

    final filename = file.filename!;
    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : null;
    if (extension == null || !knownCommentCodeExtensions.contains(extension)) {
      return false;
    }

    // Only handles single-line comments; identifying multi-line comments
    // would require the full file and non-trivial parsing. Also doesn't handle
    // end-of-line comments (e.g., "int x = 0; // Info about x").
    final commentRegex = RegExp(r'^[+-]\s*//');
    final onlyWhitespaceRegex = RegExp(r'^[+-]\s*$');
    for (var line in patch.split('\n')) {
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

  /// Release tooling generates cherrypick pull requests that should be granted an approval.
  Future<void> _tryReleaseApproval(PullRequestEvent pullRequestEvent) async {
    final pr = pullRequestEvent.pullRequest!;
    final slug = pullRequestEvent.repository!.slug();

    final defaultBranch = Config.defaultBranch(slug);
    final branch = pr.base?.ref;
    if (branch == null || branch.contains(defaultBranch)) {
      // This isn't a release branch PR
      return;
    }

    final releaseAccounts = await config.releaseAccounts;
    if (releaseAccounts.contains(pr.user?.login) == false) {
      // The author isn't in the list of release accounts, do nothing
      return;
    }

    final gitHubClient = config.createGitHubClientWithToken(
      await config.githubOAuthToken,
    );
    final review = CreatePullRequestReview(
      slug.owner,
      slug.name,
      pr.number!,
      'APPROVE',
    );
    await gitHubClient.pullRequests.createReview(slug, review);
  }

  Future<void> _processLabels(PullRequest pullRequest) async {
    final slug = pullRequest.base!.repo!.slug();
    final githubService = await config.createGithubService(slug);

    final labelProcessor = pullRequestLabelProcessorProvider(
      config: config,
      githubService: githubService,
      pullRequest: pullRequest,
    );

    return labelProcessor.processLabels();
  }

  Future<void> _scheduleIfMergeable(PullRequestEvent pullRequestEvent) async {
    final pr = pullRequestEvent.pullRequest!;
    final slug = pullRequestEvent.repository!.slug();
    final sha = pr.head!.sha!;

    if (scheduledSha == sha) {
      log.info('Presubmits already scheduled for SHA $sha. Skipping.');
      return;
    }

    log.info(
      'Scheduling tasks if mergeable(${pr.mergeable}): owner=${slug.owner} repo=${slug.name} and pr=${pr.number}',
    );

    if (pr.mergeable == false) {
      final slug = pullRequestEvent.repository!.slug();
      final gitHubClient = await config.createGitHubClient(pullRequest: pr);
      final body = config.mergeConflictPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, body)) {
        await gitHubClient.issues.createComment(slug, pr.number!, body);
      }
      return;
    }

    try {
      await scheduler.triggerPresubmitTargets(pullRequest: pr);
      scheduledSha = sha; // Update scheduled SHA!
      await _processLabels(pr);
    } on DetailedApiRequestError catch (e) {
      if (e.status != HttpStatus.conflict) {
        rethrow;
      }
      await _warnThatANewCommitIsNeeded(pullRequestEvent);
    }
  }

  Future<void> _warnThatANewCommitIsNeeded(
    PullRequestEvent pullRequestEvent,
  ) async {
    final pr = pullRequestEvent.pullRequest!;
    final slug = pullRequestEvent.repository!.slug();
    final sha = pr.head!.sha!;

    final gitHubClient = config.createGitHubClientWithToken(
      await config.githubOAuthToken,
    );
    await gitHubClient.issues.createComment(
      slug,
      pr.number!,
      Config.newCommitIsNeeded(sha: sha),
    );
  }

  /// Update the PR stored in [PrCheckRuns] so that subsequent checks are fresh.
  Future<void> _updatePullRequest(PullRequest pr) async {
    final sha = pr.head!.sha!;
    final didUpdate = await PrCheckRuns.updatePullRequestForSha(
      firestore,
      sha,
      pr,
    );
    if (!didUpdate) {
      log.debug('No PR found for SHA: $sha, did not update');
    } else {
      log.debug('Updated PR for SHA: $sha');
    }
  }
}

class PullRequestEventContext {
  final CacheService cache;
  final FirestoreService firestore;
  final Config config;
  final Scheduler scheduler;
  final GerritService gerritService;
  final PullRequestLabelProcessorProvider pullRequestLabelProcessorProvider;

  PullRequestEventContext({
    required this.cache,
    required this.firestore,
    required this.config,
    required this.scheduler,
    required this.gerritService,
    required this.pullRequestLabelProcessorProvider,
  });
}

typedef PullRequestLabelProcessorProvider =
    PullRequestLabelProcessor Function({
      required Config config,
      required GithubService githubService,
      required PullRequest pullRequest,
    });

class PullRequestLabelProcessor {
  PullRequestLabelProcessor({
    required this.config,
    required this.githubService,
    required this.pullRequest,
  }) : slug = pullRequest.base!.repo!.slug(),
       prNumber = pullRequest.number!;

  static const kEmergencyLabelEducation = '''
Detected the `emergency` label.

If you add the `autosubmit` label, the bot will wait until all presubmits pass but ignore the tree status, allowing fixes for tree breakages while still validating that they don't break any existing presubmits.

The "Merge" button is also unlocked. To bypass presubmits as well as the tree status, press the GitHub "Add to Merge Queue".
''';

  final Config config;
  final GithubService githubService;
  final PullRequest pullRequest;
  final RepositorySlug slug;
  final int prNumber;
  late final String logCrumb =
      '$PullRequestLabelProcessor($slug/pull/$prNumber)';

  void logInfo(Object? message) {
    log.info('$logCrumb: $message');
  }

  void logSevere(Object? message, {Object? error, StackTrace? stackTrace}) {
    log.error('$logCrumb: $message', error, stackTrace);
  }

  Future<void> processLabels() async {
    final hasEmergencyLabel =
        pullRequest.labels?.any(
          (label) => label.name == Config.kEmergencyLabel,
        ) ??
        false;
    if (hasEmergencyLabel) {
      // The merge guard and Flutter Presubmits check can be unlocked without approval checks because:
      //
      // * For manual merges the GitHub repo settings already require minimum
      //   approvals before the PR can be submitted.
      // * For `autosubmit` label Cocoon has the [Approval] validation that
      //   checks approvals before attempting to merge the PR.
      await _unlockCheckrunsForEmergency();
    } else {
      logInfo('no emergency label; moving on.');
    }
  }

  Future<void> _unlockCheckrunsForEmergency() async {
    await _unlockCheckrun(Config.kMergeQueueLockName);
    await _unlockCheckrun(Config.kFlutterPresubmitsName);

    // Let the developer know what is happening with the MQ when this label is found the first time.
    try {
      if (!await githubService.commentExists(
        slug,
        prNumber,
        PullRequestLabelProcessor.kEmergencyLabelEducation,
      )) {
        await githubService.createComment(
          slug,
          issueNumber: prNumber,
          body: PullRequestLabelProcessor.kEmergencyLabelEducation,
        );
      }
    } catch (e, s) {
      logSevere(
        'failed to leave educational comment for emergency label.',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _unlockCheckrun(String checkName) async {
    logInfo('attempting to unlock the $checkName for emergency');

    final guard = (await githubService.getCheckRunsFiltered(
      slug: slug,
      ref: pullRequest.head!.sha!,
      checkName: checkName,
    )).singleOrNull;

    if (guard == null) {
      logSevere(
        'failed to process the emergency label. "$checkName" check run is missing.',
      );
      return;
    }

    await githubService.updateCheckRun(
      slug: slug,
      checkRun: guard,
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.success,
      output: CheckRunOutput(
        title: checkName,
        summary: 'Emergency label applied.',
      ),
    );

    logInfo('unlocked "$checkName", allowing it to land as an emergency.');
  }
}
