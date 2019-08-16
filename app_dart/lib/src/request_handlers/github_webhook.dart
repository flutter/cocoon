// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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

@immutable
class GithubWebhook extends RequestHandler<Body> {
  const GithubWebhook(Config config, this.buildBucketClient)
      : assert(buildBucketClient != null),
        super(config: config);

  /// A client for querying and scheduling LUCI Builds.
  final BuildBucketClient buildBucketClient;

  @override
  Future<Body> post() async {
    final String gitHubEvent = request.headers.value('X-GitHub-Event');
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
      }

      return Body.empty;
    } on FormatException {
      throw const BadRequestException('Could not process input data.');
    }
  }

  Future<void> _handlePullRequest(String rawRequest) async {
    final PullRequestEvent event = await _getPullRequest(rawRequest);
    final List<IssueLabel> labels = _getLabels(rawRequest);
    if (event == null) {
      throw const BadRequestException('Expected pull request event.');
    }
    // See the API reference:
    // https://developer.github.com/v3/activity/events/types/#pullrequestevent
    // which unfortunately is a bit light on explanations.
    switch (event.action) {
      case 'opened':
      case 'reopened':
        await _checkForLabelsAndTests(event);
        break;

      case 'labeled':
        await _scheduleIfMergeable(
          event,
          cancelRunningBuilds: false,
          labels: labels,
        );
        break;
      case 'synchronize':
        await _scheduleIfMergeable(
          event,
          cancelRunningBuilds: true,
          labels: labels,
        );
        break;
      case 'unlabeled':
        if (!await _checkForCqLabel(labels)) {
          await _cancelLuci(
            event.repository.name,
            event.number,
            event.pullRequest.head.sha,
            'Tryjobs canceled (label removed)',
          );
        }
        break;
      case 'closed':
      case 'assigned':
      case 'unassigned':
      case 'review_requested':
      case 'review_request_removed':
      case 'edited':
      case 'ready_for_review':
      case 'locked':
      case 'unlocked':
        break;
    }
  }

  Future<void> _scheduleIfMergeable(
    PullRequestEvent event, {
    @required bool cancelRunningBuilds,
    @required List<IssueLabel> labels,
  }) async {
    assert(cancelRunningBuilds != null);
    if (cancelRunningBuilds) {
      await _cancelLuci(
        event.repository.name,
        event.number,
        event.pullRequest.head.sha,
        'Newer commit available',
      );
    }
    // The mergeable flag may be null. False indicates there's a merge conflict,
    // null indicates unknown. Err on the side of allowing the job to run.
    if (event.pullRequest.mergeable != false && await _checkForCqLabel(labels)) {
      await _scheduleLuci(
        number: event.number,
        sha: event.pullRequest.head.sha,
        repositoryName: event.repository.name,
        skipRunningCheck: cancelRunningBuilds,
      );
    }
  }

  Future<List<Build>> _buildsForRepositoryAndPr(
    String repositoryName,
    int number,
    String sha,
    BuildBucketClient buildBucketClient,
    ServiceAccountInfo serviceAccount,
  ) async {
    final SearchBuildsResponse response = await buildBucketClient.searchBuilds(
      SearchBuildsRequest(
        predicate: BuildPredicate(
          builderId: const BuilderId(
            project: 'flutter',
            bucket: 'try',
          ),
          createdBy: serviceAccount.email,
          tags: <String, List<String>>{
            'buildset': <String>['pr/git/$number'],
            'github_link': <String>['https://github.com/flutter/$repositoryName/pulls/$number'],
            'user_agent': const <String>['flutter-cocoon'],
          },
        ),
      ),
    );
    return response.builds;
  }

  Future<bool> _scheduleLuci({
    @required int number,
    @required String sha,
    @required String repositoryName,
    bool skipRunningCheck = false,
  }) async {
    assert(number != null);
    assert(sha != null);
    assert(repositoryName != null);
    assert(skipRunningCheck != null);
    if (repositoryName != 'flutter' && repositoryName != 'engine') {
      log.error('Unsupported repo on webhook: $repositoryName');
      throw BadRequestException('Repository $repositoryName is not supported by this service.');
    }
    final ServiceAccountInfo serviceAccount = await config.deviceLabServiceAccount;

    if (!skipRunningCheck) {
      final List<Build> builds = await _buildsForRepositoryAndPr(
        repositoryName,
        number,
        sha,
        buildBucketClient,
        serviceAccount,
      );
      if (builds != null &&
          builds.any((Build build) {
            return build.status == Status.scheduled || build.status == Status.started;
          })) {
        return false;
      }
    }

    final List<Map<String, dynamic>> builders = await config.luciTryBuilders;
    final List<String> builderNames = builders
        .where((Map<String, dynamic> builder) => builder['repo'] == repositoryName)
        .map<String>((Map<String, dynamic> builder) => builder['name'])
        .toList();

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
              'github_link': <String>['https://github.com/flutter/$repositoryName/pulls/$number'],
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
    final BatchResponse luciResponse =
        await buildBucketClient.batch(BatchRequest(requests: requests));
    return true;
  }

  /// Checks the issue in the given repository for `config.cqLabelName`.
  Future<bool> _checkForCqLabel(List<IssueLabel> labels) async {
    final String cqLabelName = await config.cqLabelName;
    return labels.any((IssueLabel label) => label.name == cqLabelName);
  }

  // TODO(dnfield): Eliminate when github.dart has this in the model
  List<IssueLabel> _getLabels(String pullRequestJson) {
    final Map<String, dynamic> decoded = json.decode(pullRequestJson);
    final Map<String, dynamic> decodedPr = decoded['pull_request'];
    return decodedPr['labels']
        .cast<Map<String, dynamic>>()
        .map<IssueLabel>(IssueLabel.fromJSON)
        .toList();
  }

  Future<void> _cancelLuci(String repositoryName, int number, String sha, String reason) async {
    if (repositoryName != 'flutter' && repositoryName != 'engine') {
      throw BadRequestException('This service does not support repository $repositoryName.');
    }
    final ServiceAccountInfo serviceAccount = await config.deviceLabServiceAccount;
    final List<Build> builds = await _buildsForRepositoryAndPr(
      repositoryName,
      number,
      sha,
      buildBucketClient,
      serviceAccount,
    );
    if (builds == null ||
        !builds.any((Build build) {
          return build.status == Status.scheduled || build.status == Status.started;
        })) {
      return;
    }
    final List<Request> requests = <Request>[];
    for (Build build in builds) {
      requests.add(
        Request(
          cancelBuild: CancelBuildRequest(id: build.id, summaryMarkdown: reason),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
  }

  Future<void> _checkForLabelsAndTests(PullRequestEvent event) async {
    if (event.repository.fullName.toLowerCase() == 'flutter/flutter') {
      final GitHub gitHubClient = await config.createGitHubClient();
      try {
        await _checkBaseRef(gitHubClient, event);
        await _applyLabels(gitHubClient, event);
      } finally {
        gitHubClient.dispose();
      }
    }
  }

  Future<void> _applyLabels(GitHub gitHubClient, PullRequestEvent event) async {
    if (event.sender.login == 'engine-flutter-autoroll') {
      return;
    }
    final RepositorySlug slug = event.repository.slug();
    // TODO(dnfield): Use event.pullRequests.listFiles API when it's fixed: DirectMyFile/github.dart#151
    final List<PullRequestFile> files =
        await gitHubClient.getJSON<List<dynamic>, List<PullRequestFile>>(
      '/repos/${slug.fullName}/pulls/${event.number}/files',
      convert: (List<dynamic> jsonFileList) =>
          jsonFileList.cast<Map<String, dynamic>>().map(PullRequestFile.fromJSON).toList(),
    );
    bool hasTests = false;
    bool needsTests = false;
    final Set<String> labels = <String>{};
    for (PullRequestFile file in files) {
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

      if (file.filename.contains('semantics') || file.filename.contains('accessibilty')) {
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
    if (labels.isNotEmpty) {
      // TODO(dnfield): This should be addLabelsToIssue when that is fixed. DirectMyFile/github.dart#152
      await gitHubClient.postJSON<List<dynamic>, List<IssueLabel>>(
        '/repos/${slug.fullName}/issues/${event.number}/labels',
        body: jsonEncode(labels.toList()),
        convert: (List<dynamic> input) =>
            input.cast<Map<String, dynamic>>().map(IssueLabel.fromJSON).toList(),
      );
    }
    if (!hasTests && needsTests) {
      // Googlers can edit this at http://shortn/_GjZ5AgUqV2
      final String body = await config.missingTestsPullRequestMessage;
      await gitHubClient.issues.createComment(slug, event.number, body);
    }
  }

  Future<void> _checkBaseRef(
    GitHub gitHubClient,
    PullRequestEvent event,
  ) async {
    if (event.pullRequest.base.ref != 'master') {
      final String body = await _getWrongBaseComment(event.pullRequest.base.ref);
      final RepositorySlug slug = event.repository.slug();

      await gitHubClient.pullRequests.edit(slug, event.number, base: 'master');
      await gitHubClient.issues.createComment(slug, event.number, body);
    }
  }

  Future<String> _getWrongBaseComment(String base) async {
    final String messageTemplate = await config.nonMasterPullRequestMessage;
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
      final PullRequestEvent event = PullRequestEvent.fromJSON(json.decode(request));

      if (event == null) {
        return null;
      }

      return event;
    } on FormatException {
      return null;
    }
  }
}
