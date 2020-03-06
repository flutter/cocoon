// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/service_account_info.dart';
import '../model/luci/buildbucket.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../service/buildbucket.dart';

/// List of Github supported repos.
const Set<String> supportedRepos = <String>{'engine', 'flutter', 'cocoon'};

/// List of repos that require CQ+1 label.
const Set<String> needsCQLabelList = <String>{'flutter/flutter'};

@immutable
class GithubWebhook extends RequestHandler<Body> {
  GithubWebhook(Config config, this.buildBucketClient, {HttpClient skiaClient})
      : assert(buildBucketClient != null),
        skiaClient = skiaClient ?? HttpClient(),
        super(config: config);

  /// A client for querying and scheduling LUCI Builds.
  final BuildBucketClient buildBucketClient;

  /// An Http Client for querying the Skia Gold API.
  final HttpClient skiaClient;

  @override
  Future<Body> post() async {
    final String gitHubEvent = request.headers.value('X-GitHub-Event');
    if (gitHubEvent == null ||
        request.headers.value('X-Hub-Signature') == null) {
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
      }

      return Body.empty;
    } on FormatException {
      throw const BadRequestException('Could not process input data.');
    } on InternalServerError {
      rethrow;
    }
  }

  Future<void> _handlePullRequest(String rawRequest) async {
    final PullRequestEvent event = await _getPullRequest(rawRequest);
    final List<IssueLabel> existingLabels =
        _getProperty<List<dynamic>>(rawRequest, 'labels')
            .cast<Map<String, dynamic>>()
            .map<IssueLabel>(IssueLabel.fromJSON)
            .toList();
    final bool isDraft = _getProperty(rawRequest, 'draft');
    if (event == null) {
      throw const BadRequestException('Expected pull request event.');
    }
    // See the API reference:
    // https://developer.github.com/v3/activity/events/types/#pullrequestevent
    // which unfortunately is a bit light on explanations.
    switch (event.action) {
      case 'closed':
        // On a successful merge, check for gold.
        // If it was closed without merging, cancel any outstanding tryjobs.
        // We'll leave unfinished jobs if it was merged since we care about those
        // results.
        if (event.pullRequest.merged) {
          await _checkForGoldenTriage(
            event,
            existingLabels,
          );
        } else {
          await _cancelLuci(
            event.repository.name,
            event.number,
            event.pullRequest.head.sha,
            'Pull request closed',
          );
        }
        break;
      case 'edited':
        // Editing a PR should not trigger new jobs, but may update whether
        // it has tests.
        await _checkForLabelsAndTests(event, isDraft);
        break;
      case 'opened':
      case 'ready_for_review':
      case 'reopened':
        // These cases should trigger LUCI jobs.
        await _checkForLabelsAndTests(event, isDraft);
        await _scheduleIfMergeable(
          event,
          labels: existingLabels,
        );
        break;
      case 'labeled':
        // This should only trigger a LUCI job for flutter/flutter right now,
        // since it is in the needsCQLabelList.
        if (needsCQLabelList
            .contains(event.repository.fullName.toLowerCase())) {
          await _scheduleIfMergeable(
            event,
            labels: existingLabels,
          );
        }
        break;
      case 'synchronize':
        // This indicates the PR has new commits. We need to cancel old jobs
        // and schedule new ones.
        await _scheduleIfMergeable(
          event,
          labels: existingLabels,
        );
        break;
      case 'unlabeled':
        // Cancel the jobs if someone removed the label on a repo that needs
        // them.
        if (!needsCQLabelList
            .contains(event.repository.fullName.toLowerCase())) {
          break;
        }
        if (!await _checkForCqLabel(existingLabels)) {
          await _cancelLuci(
            event.repository.name,
            event.number,
            event.pullRequest.head.sha,
            'Tryjobs canceled (label removed)',
          );
        }
        break;
      // Ignore the rest of the events.
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
    PullRequestEvent event, {
    @required List<IssueLabel> labels,
  }) async {
    // The mergeable flag may be null. False indicates there's a merge conflict,
    // null indicates unknown. Err on the side of allowing the job to run.

    // For flutter/flutter tests need to be optimized before enforcing CQ.
    if (needsCQLabelList.contains(event.repository.fullName.toLowerCase())) {
      if (!await _checkForCqLabel(labels)) {
        return;
      }
    }

    // Always cancel running builds so we don't ever schedule duplicates.
    await _cancelLuci(
      event.repository.name,
      event.number,
      event.pullRequest.head.sha,
      'Newer commit available',
    );
    await _scheduleLuci(
      number: event.number,
      sha: event.pullRequest.head.sha,
      repositoryName: event.repository.name,
    );
  }

  /// This method checks if there are running builds for this PR
  Future<List<Build>> _buildsForRepositoryAndPr(
    String repositoryName,
    int number,
    String sha,
    BuildBucketClient buildBucketClient,
    ServiceAccountInfo serviceAccount,
  ) async {
    final BatchResponse batch =
        await buildBucketClient.batch(BatchRequest(requests: <Request>[
      Request(
        searchBuilds: SearchBuildsRequest(
          predicate: BuildPredicate(
            builderId: const BuilderId(
              project: 'flutter',
              bucket: 'try',
            ),
            createdBy: serviceAccount.email,
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/$number'],
              'github_link': <String>[
                'https://github.com/flutter/$repositoryName/pull/$number'
              ],
              'user_agent': const <String>['flutter-cocoon'],
            },
          ),
        ),
      ),
      Request(
        searchBuilds: SearchBuildsRequest(
          predicate: BuildPredicate(
            builderId: const BuilderId(
              project: 'flutter',
              bucket: 'try',
            ),
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/$number'],
              'user_agent': const <String>['recipe'],
            },
          ),
        ),
      ),
    ]));
    return batch.responses
        .map((Response response) => response.searchBuilds)
        .expand((SearchBuildsResponse response) => response.builds ?? <Build>[])
        .toList();
  }

  Future<bool> _scheduleLuci({
    @required int number,
    @required String sha,
    @required String repositoryName,
  }) async {
    assert(number != null);
    assert(sha != null);
    assert(repositoryName != null);
    if (!supportedRepos.contains(repositoryName)) {
      log.error('Unsupported repo on webhook: $repositoryName');
      throw BadRequestException(
          'Repository $repositoryName is not supported by this service.');
    }
    final ServiceAccountInfo serviceAccount =
        await config.deviceLabServiceAccount;

    final List<Build> builds = await _buildsForRepositoryAndPr(
      repositoryName,
      number,
      sha,
      buildBucketClient,
      serviceAccount,
    );
    if (builds != null &&
        builds.any((Build build) {
          return build.status == Status.scheduled ||
              build.status == Status.started;
        })) {
      return false;
    }

    final List<Map<String, dynamic>> builders = config.luciTryBuilders;
    final List<String> builderNames = builders
        .where(
            (Map<String, dynamic> builder) => builder['repo'] == repositoryName)
        .map<String>(
            (Map<String, dynamic> builder) => builder['name'] as String)
        .toList();
    if (builderNames.isEmpty) {
      throw InternalServerError('$repositoryName does not have any builders');
    }

    final List<Request> requests = <Request>[];
    for (String builder in builderNames) {
      final BuilderId builderId = BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: builder,
      );
      requests.add(
        Request(
          scheduleBuild: ScheduleBuildRequest(
            builderId: builderId,
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/$number', 'sha/git/$sha'],
              'user_agent': const <String>['flutter-cocoon'],
              'github_link': <String>[
                'https://github.com/flutter/$repositoryName/pull/$number'
              ],
            },
            properties: <String, String>{
              'git_url': 'https://github.com/flutter/$repositoryName',
              'git_ref': 'refs/pull/$number/head',
            },
            notify: NotificationConfig(
              pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
              userData: json.encode(const <String, dynamic>{
                'retries': 0,
              }),
            ),
          ),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
    return true;
  }

  /// Checks the issue in the given repository for `config.cqLabelName`.
  Future<bool> _checkForCqLabel(List<IssueLabel> labels) async {
    final String cqLabelName = config.cqLabelName;
    return labels.any((IssueLabel label) => label.name == cqLabelName);
  }

  // Eliminate when github.dart implements missing features:
  // TODO(dnfield): labels - https://github.com/DirectMyFile/github.dart/pull/155
  // TODO(Piinks): drafts - https://github.com/DirectMyFile/github.dart/issues/161
  T _getProperty<T>(String pullRequestJson, String property) {
    final Map<String, dynamic> decoded =
        json.decode(pullRequestJson) as Map<String, dynamic>;
    final Map<String, dynamic> decodedPr =
        decoded['pull_request'] as Map<String, dynamic>;
    return decodedPr[property] as T;
  }

  Future<void> _cancelLuci(
      String repositoryName, int number, String sha, String reason) async {
    if (!supportedRepos.contains(repositoryName)) {
      throw BadRequestException(
          'This service does not support repository $repositoryName.');
    }
    final ServiceAccountInfo serviceAccount =
        await config.deviceLabServiceAccount;
    final List<Build> builds = await _buildsForRepositoryAndPr(
      repositoryName,
      number,
      sha,
      buildBucketClient,
      serviceAccount,
    );
    if (builds == null ||
        !builds.any((Build build) {
          return build.status == Status.scheduled ||
              build.status == Status.started;
        })) {
      return;
    }
    final List<Request> requests = <Request>[];
    for (Build build in builds) {
      requests.add(
        Request(
          cancelBuild:
              CancelBuildRequest(id: build.id, summaryMarkdown: reason),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
  }

  Future<bool> _isIgnoredForGold(PullRequestEvent event) async {
    bool ignored = false;
    String rawResponse;
    try {
      final HttpClientRequest request = await skiaClient
          .getUrl(Uri.parse('https://flutter-gold.skia.org/json/ignores'));
      final HttpClientResponse response = await request.close();
      rawResponse = await utf8.decodeStream(response);
      final List<dynamic> ignores = jsonDecode(rawResponse) as List<dynamic>;
      for (Map<String, dynamic> ignore
          in ignores.cast<Map<String, dynamic>>()) {
        if ((ignore['note'] as String).isNotEmpty &&
            event.number.toString() == ignore['note'].split('/').last) {
          ignored = true;
          break;
        }
      }
    } on IOException catch (e) {
      log.error('Request to Flutter Gold for ignores failed for PR '
          '#${event.number} on action: ${event.action}.\n'
          'error: $e');
    } on FormatException catch (_) {
      log.error('Format Exception from Flutter Gold ignore request.\n'
          'rawResponse: $rawResponse');
      rethrow;
    }
    return ignored;
  }

  Future<void> _checkForGoldenTriage(
    PullRequestEvent event,
    List<IssueLabel> labels,
  ) async {
    if (event.repository.fullName.toLowerCase() == 'flutter/flutter' &&
        await _isIgnoredForGold(event)) {
      final GitHub gitHubClient = await config.createGitHubClient();
      try {
        await _pingForTriage(gitHubClient, event);
      } finally {
        gitHubClient.dispose();
      }
    }
  }

  Future<void> _pingForTriage(
      GitHub gitHubClient, PullRequestEvent event) async {
    final String body = config.goldenTriageMessage;
    final RepositorySlug slug = event.repository.slug();
    await gitHubClient.issues.createComment(slug, event.number, body);
  }

  Future<void> _checkForLabelsAndTests(
    PullRequestEvent event,
    bool isDraft,
  ) async {
    if (event.repository.fullName.toLowerCase() == 'flutter/flutter') {
      final GitHub gitHubClient = await config.createGitHubClient();
      try {
        await _checkBaseRef(gitHubClient, event);
        await _applyLabels(gitHubClient, event, isDraft);
      } finally {
        gitHubClient.dispose();
      }
    }
  }

  Future<void> _applyLabels(
    GitHub gitHubClient,
    PullRequestEvent event,
    bool isDraft,
  ) async {
    if (event.sender.login == 'engine-flutter-autoroll') {
      return;
    }
    final RepositorySlug slug = event.repository.slug();
    final Stream<PullRequestFile> files =
        gitHubClient.pullRequests.listFiles(slug, event.number);
    final Set<String> labels = <String>{};
    bool hasTests = false;
    bool needsTests = false;
    bool isGoldenChange = false;

    await for (PullRequestFile file in files) {
      if (file.filename.endsWith('pubspec.yaml')) {
        // These get updated by a script, and are updated en masse.
        labels.add('team');
        continue;
      }
      if (file.filename.endsWith('.dart')) {
        needsTests = true;
      }
      if (file.filename.endsWith('_test.dart')) {
        hasTests = true;
      }

      if (file.filename.startsWith('dev/')) {
        labels.add('team');
      }
      if (file.filename.startsWith('packages/flutter_tools/') ||
          file.filename.startsWith('packages/fuchsia_remote_debug_protocol')) {
        labels.add('tool');
      }
      if (file.filename == 'bin/internal/engine.version') {
        labels.add('engine');
      }
      if (await _isIgnoredForGold(event)) {
        isGoldenChange = true;
        labels.add('will affect goldens');
        labels.add('severe: API break');
        labels.add('a: tests');
      }

      if (file.filename.startsWith('packages/flutter/') ||
          file.filename.startsWith('packages/flutter_test/') ||
          file.filename.startsWith('packages/flutter_driver/')) {
        labels.add('framework');
      }
      if (file.filename.contains('material')) {
        labels.add('f: material design');
      }
      if (file.filename.contains('cupertino')) {
        labels.add('f: cupertino');
      }

      if (file.filename.startsWith('packages/flutter_localizations')) {
        labels.add('a: internationalization');
      }

      if (file.filename.startsWith('packages/flutter_test') ||
          file.filename.startsWith('packages/flutter_driver')) {
        labels.add('a: tests');
      }

      if (file.filename.contains('semantics') ||
          file.filename.contains('accessibilty')) {
        labels.add('a: accessibility');
      }

      if (file.filename.startsWith('examples/')) {
        labels.add('d: examples');
        labels.add('team');
        if (file.filename.startsWith('examples/flutter_gallery')) {
          labels.add('team: gallery');
        }
      }
    }

    if (isDraft) {
      labels.add('work in progress; do not review');
    }

    if (labels.isNotEmpty) {
      await gitHubClient.issues
          .addLabelsToIssue(slug, event.number, labels.toList());
    }

    if (!hasTests && needsTests && !isDraft) {
      final String body = config.missingTestsPullRequestMessage;
      if (!await _alreadyCommented(gitHubClient, event, slug, body)) {
        await gitHubClient.issues.createComment(slug, event.number, body);
      }
    }

    if (isGoldenChange) {
      final String body = config.goldenBreakingChangeMessage;
      if (!await _alreadyCommented(gitHubClient, event, slug, body)) {
        await gitHubClient.issues.createComment(slug, event.number, body);
      }
    }
  }

  Future<void> _checkBaseRef(
    GitHub gitHubClient,
    PullRequestEvent event,
  ) async {
    if (event.pullRequest.base.ref != 'master') {
      final String body =
          await _getWrongBaseComment(event.pullRequest.base.ref);
      final RepositorySlug slug = event.repository.slug();
      if (!await _alreadyCommented(gitHubClient, event, slug, body)) {
        await gitHubClient.pullRequests.edit(
          slug,
          event.number,
          base: 'master',
        );
        await gitHubClient.issues.createComment(slug, event.number, body);
      }
    }
  }

  Future<bool> _alreadyCommented(
    GitHub gitHubClient,
    PullRequestEvent event,
    RepositorySlug slug,
    String message,
  ) async {
    final Stream<IssueComment> comments =
        gitHubClient.issues.listCommentsByIssue(slug, event.number);
    await for (IssueComment comment in comments) {
      if (comment.body.contains(message)) {
        return true;
      }
    }
    return false;
  }

  Future<String> _getWrongBaseComment(String base) async {
    final String messageTemplate = config.nonMasterPullRequestMessage;
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

  Future<PullRequestEvent> _getPullRequest(String request) async {
    if (request == null) {
      return null;
    }
    try {
      final PullRequestEvent event = PullRequestEvent.fromJSON(
          json.decode(request) as Map<String, dynamic>);

      if (event == null) {
        return null;
      }

      return event;
    } on FormatException {
      return null;
    }
  }
}
