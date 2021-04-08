// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../model/github/checks.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../service/buildbucket.dart';
import '../service/github_checks_service.dart';
import '../service/luci_build_service.dart';
import '../service/scheduler.dart';

/// List of repos that require check for labels and tests.
const Set<String> kNeedsCheckLabelsAndTests = <String>{'flutter/flutter', 'flutter/engine'};

final RegExp kEngineTestRegExp = RegExp(r'tests?\.(dart|java|mm|m|cc)$');

@immutable
class GithubWebhook extends RequestHandler<Body> {
  const GithubWebhook(
    Config config, {
    @required this.buildBucketClient,
    @required this.scheduler,
    this.luciBuildService,
    this.githubChecksService,
  })  : assert(buildBucketClient != null),
        super(config: config);

  /// A client for querying and scheduling LUCI Builds.
  final BuildBucketClient buildBucketClient;

  /// Cocoon scheduler to trigger tasks against changes from GitHub.
  final Scheduler scheduler;

  /// LUCI service class to communicate with buildBucket service.
  final LuciBuildService luciBuildService;

  /// Github checks service. Used to provide build status to github.
  final GithubChecksService githubChecksService;

  @override
  Future<Body> post() async {
    final String gitHubEvent = request.headers.value('X-GitHub-Event');

    // Set service class logger.
    luciBuildService.setLogger(log);
    githubChecksService.setLogger(log);
    scheduler.setLogger(log);

    if (gitHubEvent == null || request.headers.value('X-Hub-Signature') == null) {
      throw const BadRequestException('Missing required headers.');
    }
    final List<int> requestBytes = await request.expand((_) => _).toList();
    final String hmacSignature = request.headers.value('X-Hub-Signature');
    if (!await _validateRequest(hmacSignature, requestBytes)) {
      throw const Forbidden();
    }

    try {
      final String stringRequest = utf8.decode(requestBytes);
      switch (gitHubEvent) {
        case 'pull_request':
          await _handlePullRequest(stringRequest);
          break;
        case 'check_run':
          final CheckRunEvent checkRunEvent = CheckRunEvent.fromJson(
            jsonDecode(stringRequest) as Map<String, dynamic>,
          );
          await githubChecksService.handleCheckRun(checkRunEvent, luciBuildService);
      }

      return Body.empty;
    } on FormatException {
      throw const BadRequestException('Could not process input data.');
    } on InternalServerError {
      rethrow;
    }
  }

  Future<void> _handlePullRequest(
    String rawRequest,
  ) async {
    final PullRequestEvent pullRequestEvent = await _getPullRequestEvent(rawRequest);
    if (pullRequestEvent == null) {
      throw const BadRequestException('Expected pull request event.');
    }
    final String eventAction = pullRequestEvent.action;
    final PullRequest pr = pullRequestEvent.pullRequest;

    // See the API reference:
    // https://developer.github.com/v3/activity/events/types/#pullrequestevent
    // which unfortunately is a bit light on explanations.
    switch (eventAction) {
      case 'closed':
        // If it was closed without merging, cancel any outstanding tryjobs.
        // We'll leave unfinished jobs if it was merged since we care about those
        // results.
        if (!pr.merged) {
          await luciBuildService.cancelBuilds(
            pullRequestEvent.repository.slug(),
            pr.number,
            pr.head.sha,
            'Pull request closed',
          );
        } else {
          // Merged pull requests can be added to CI.
          await scheduler.addPullRequest(pr);
        }
        break;
      case 'edited':
        // Editing a PR should not trigger new jobs, but may update whether
        // it has tests.
        await _checkForLabelsAndTests(pullRequestEvent);
        break;
      case 'opened':
      case 'ready_for_review':
      case 'reopened':
        // These cases should trigger LUCI jobs.
        await _checkForLabelsAndTests(pullRequestEvent);
        await _scheduleIfMergeable(pullRequestEvent);
        break;
      case 'labeled':
        break;
      case 'synchronize':
        // This indicates the PR has new commits. We need to cancel old jobs
        // and schedule new ones.
        await _scheduleIfMergeable(pullRequestEvent);
        break;
      // Ignore the rest of the events.
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

  /// This method assumes that jobs should be cancelled if they are already
  /// runnning.
  Future<void> _scheduleIfMergeable(
    PullRequestEvent pullRequestEvent,
  ) async {
    final PullRequest pr = pullRequestEvent.pullRequest;

    // The mergeable flag may be null. False indicates there's a merge conflict,
    // null indicates unknown. Err on the side of allowing the job to run.
    if (pr.mergeable == false) {
      final RepositorySlug slug = pullRequestEvent.repository.slug();
      final GitHub gitHubClient = await config.createGitHubClient(
        slug.owner,
        slug.name,
      );
      final String body = config.mergeConflictPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, slug, body)) {
        await gitHubClient.issues.createComment(slug, pr.number, body);
      }

      return;
    }

    // Always cancel running builds so we don't ever schedule duplicates.
    await luciBuildService.cancelBuilds(
      pullRequestEvent.repository.slug(),
      pr.number,
      pr.head.sha,
      'Newer commit available',
    );
    await luciBuildService.scheduleTryBuilds(
      slug: pullRequestEvent.repository.slug(),
      prNumber: pr.number,
      commitSha: pr.head.sha,
    );
  }

  Future<void> _checkForLabelsAndTests(PullRequestEvent pullRequestEvent) async {
    final PullRequest pr = pullRequestEvent.pullRequest;
    final String eventAction = pullRequestEvent.action;
    final RepositorySlug slug = pullRequestEvent.repository.slug();
    final String repo = pr.base.repo.fullName.toLowerCase();
    if (kNeedsCheckLabelsAndTests.contains(repo)) {
      final GitHub gitHubClient = await config.createGitHubClient(slug.owner, slug.name);
      try {
        await _validateRefs(gitHubClient, pr);
        if (repo == 'flutter/flutter') {
          await _applyFrameworkRepoLabels(gitHubClient, eventAction, pr);
        } else if (repo == 'flutter/engine') {
          await _applyEngineRepoLabels(gitHubClient, eventAction, pr);
        }
      } finally {
        gitHubClient.dispose();
      }
    }
  }

  Future<void> _applyFrameworkRepoLabels(GitHub gitHubClient, String eventAction, PullRequest pr) async {
    if (pr.user.login == 'engine-flutter-autoroll') {
      return;
    }
    final RepositorySlug slug = pr.base.repo.slug();
    log.info('Applying framework repo labels for: owner=${slug.owner} repo=${slug.name} and pr=${pr.number}');
    final Stream<PullRequestFile> files = gitHubClient.pullRequests.listFiles(slug, pr.number);
    final Set<String> labels = <String>{};
    bool hasTests = false;
    bool needsTests = false;

    await for (PullRequestFile file in files) {
      if (file.filename.endsWith('.dart') &&
          !file.filename.startsWith('dev/devicelab/bin/tasks') &&
          !file.filename.startsWith('dev/bots/')) {
        needsTests = true;
      }
      if (file.filename.endsWith('_test.dart')) {
        hasTests = true;
      }
      labels.addAll(getLabelsForFrameworkPath(file.filename));
    }

    if (labels.isNotEmpty) {
      await gitHubClient.issues.addLabelsToIssue(slug, pr.number, labels.toList());
    }

    if (!hasTests && needsTests && !pr.draft) {
      final String body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, slug, body)) {
        await gitHubClient.issues.createComment(slug, pr.number, body);
      }
    }
  }

  /// Returns the set of labels applicable to a file in the framework repo.
  static Set<String> getLabelsForFrameworkPath(String filepath) {
    final Set<String> labels = <String>{};
    if (filepath.endsWith('pubspec.yaml')) {
      // These get updated by a script, and are updated en masse.
      labels.add('team');
      return labels;
    }

    const Map<String, List<String>> pathPrefixLabels = <String, List<String>>{
      'bin/internal/engine.version': <String>['engine'],
      'dev/': <String>['team'],
      'examples/': <String>['d: examples', 'team'],
      'examples/flutter_gallery': <String>['d: examples', 'team', 'team: gallery'],
      'packages/flutter_tools/': <String>['tool'],
      'packages/fuchsia_remote_debug_protocol': <String>['tool'],
      'packages/flutter/': <String>['framework'],
      'packages/flutter_test/': <String>['framework', 'a: tests'],
      'packages/flutter_driver/': <String>['framework', 'a: tests'],
      'packages/flutter_localizations/': <String>['a: internationalization'],
    };
    const Map<String, List<String>> pathContainsLabels = <String, List<String>>{
      'material': <String>['f: material design'],
      'cupertino': <String>['f: cupertino'],
      'accessibility': <String>['a: accessibility'],
      'semantics': <String>['a: accessibility'],
    };

    pathPrefixLabels.forEach((String path, List<String> pathLabels) {
      if (filepath.startsWith(path)) {
        labels.addAll(pathLabels);
      }
    });
    pathContainsLabels.forEach((String path, List<String> pathLabels) {
      if (filepath.contains(path)) {
        labels.addAll(pathLabels);
      }
    });
    return labels;
  }

  /// Returns the set of labels applicable to a file in the engine repo.
  static Set<String> getLabelsForEnginePath(String filepath) {
    const Map<String, List<String>> pathPrefixLabels = <String, List<String>>{
      'shell/platform/android': <String>['platform-android'],
      'shell/platform/embedder': <String>['embedder'],
      'shell/platform/darwin/common': <String>['platform-ios', 'platform-macos'],
      'shell/platform/darwin/ios': <String>['platform-ios'],
      'shell/platform/darwin/macos': <String>['platform-macos'],
      'shell/platform/fuchsia': <String>['platform-fuchsia'],
      'shell/platform/linux': <String>['platform-linux'],
      'shell/platform/windows': <String>['platform-windows'],
      'lib/web_ui': <String>['platform-web'],
      'web_sdk': <String>['platform-web'],
    };
    final Set<String> labels = <String>{};
    pathPrefixLabels.forEach((String path, List<String> pathLabels) {
      if (filepath.startsWith(path)) {
        labels.addAll(pathLabels);
      }
    });
    return labels;
  }

  Future<void> _applyEngineRepoLabels(GitHub gitHubClient, String eventAction, PullRequest pr) async {
    if (pr.user.login == 'skia-flutter-autoroll') {
      return;
    }
    final RepositorySlug slug = pr.base.repo.slug();
    final Stream<PullRequestFile> files = gitHubClient.pullRequests.listFiles(slug, pr.number);
    final Set<String> labels = <String>{};
    bool hasTests = false;
    bool needsTests = false;

    await for (PullRequestFile file in files) {
      final String filename = file.filename.toLowerCase();
      if (filename.endsWith('.dart') ||
          filename.endsWith('.mm') ||
          filename.endsWith('.m') ||
          filename.endsWith('.java') ||
          filename.endsWith('.cc')) {
        needsTests = true;
      }

      if (kEngineTestRegExp.hasMatch(filename)) {
        hasTests = true;
      }

      labels.addAll(getLabelsForEnginePath(filename));
    }

    if (labels.isNotEmpty) {
      await gitHubClient.issues.addLabelsToIssue(slug, pr.number, labels.toList());
    }

    if (!hasTests && needsTests && !pr.draft) {
      final String body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, slug, body)) {
        await gitHubClient.issues.createComment(slug, pr.number, body);
      }
    }
  }

  /// Validate the base and head refs of the PR.
  Future<void> _validateRefs(
    GitHub gitHubClient,
    PullRequest pr,
  ) async {
    final RepositorySlug slug = pr.base.repo.slug();
    String body;
    const List<String> releaseChannels = <String>[
      'stable',
      'beta',
      'dev',
    ];
    // Close PRs that use a release branch as a source.
    if (releaseChannels.contains(pr.head.ref)) {
      body = config.wrongHeadBranchPullRequestMessage(pr.head.ref);
      if (!await _alreadyCommented(gitHubClient, pr, slug, body)) {
        await gitHubClient.pullRequests.edit(
          slug,
          pr.number,
          state: 'closed',
        );
        await gitHubClient.issues.createComment(slug, pr.number, body);
      }
      return;
    }
    if (pr.base.ref == config.defaultBranch) {
      return;
    }
    final RegExp candidateTest = RegExp(r'flutter-\d+\.\d+-candidate\.\d+');
    if (candidateTest.hasMatch(pr.base.ref) && candidateTest.hasMatch(pr.head.ref)) {
      // This is most likely a release branch
      body = config.releaseBranchPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, pr, slug, body)) {
        await gitHubClient.issues.createComment(slug, pr.number, body);
      }
      return;
    }

    // Assume this PR should be based against config.defaultBranch.
    body = _getWrongBaseComment(pr.base.ref);
    if (!await _alreadyCommented(gitHubClient, pr, slug, body)) {
      await gitHubClient.pullRequests.edit(
        slug,
        pr.number,
        base: config.defaultBranch,
      );
      await gitHubClient.issues.createComment(slug, pr.number, body);
    }
  }

  Future<bool> _alreadyCommented(
    GitHub gitHubClient,
    PullRequest pr,
    RepositorySlug slug,
    String message,
  ) async {
    final Stream<IssueComment> comments = gitHubClient.issues.listCommentsByIssue(slug, pr.number);
    await for (IssueComment comment in comments) {
      if (comment.body.contains(message)) {
        return true;
      }
    }
    return false;
  }

  String _getWrongBaseComment(String base) {
    final String messageTemplate = config.wrongBaseBranchPullRequestMessage;
    return messageTemplate.replaceAll('{{branch}}', base);
  }

  Future<bool> _validateRequest(
    String signature,
    List<int> requestBody,
  ) async {
    final String rawKey = await config.webhookKey;
    final List<int> key = utf8.encode(rawKey);
    final Hmac hmac = Hmac(sha1, key);
    final Digest digest = hmac.convert(requestBody);
    final String bodySignature = 'sha1=$digest';
    return bodySignature == signature;
  }

  Future<PullRequestEvent> _getPullRequestEvent(String request) async {
    if (request == null) {
      return null;
    }
    try {
      return PullRequestEvent.fromJson(json.decode(request) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }
}
