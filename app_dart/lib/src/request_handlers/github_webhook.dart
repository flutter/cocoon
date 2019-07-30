// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:crypto/crypto.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../github.dart';
import '../model/appengine/service_account_info.dart';
import '../model/luci/buildbucket.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../service/buildbucket.dart';

@immutable
class GithubWebhook extends RequestHandler<Body> {
  const GithubWebhook(Config config, this.clientContext) : super(config: config);

  final ClientContext clientContext;

  @override
  Future<Body> post() async {
    final String gitHubEvent = request.headers.value('X-GitHub-Event');
    if (gitHubEvent == null || request.headers.value('X-Hub-Signature') == null) {
      throw const BadRequestException('Missing required headers.');
    }

    final List<int> requestBytes = await request.expand((_) => _).toList();
    final String hmacSignature = request.headers.value('X-Hub-Signature');
    if (!await _validateRequest(hmacSignature, requestBytes)) {
      throw Forbidden();
    }

    try {
      final String stringRequest = utf8.decode(requestBytes);

      switch (gitHubEvent) {
        case 'pull_request':
          return _handlePullRequest(await getPullRequest(stringRequest));
        case 'push':
        default:
          return Body.empty;
      }
    } on FormatException {
      throw const BadRequestException();
    }
  }

  Future<Body> _handlePullRequest(PullRequestEvent event) async {
    if (event == null) {
      throw const BadRequestException();
    }
    switch (event.action) {
      case 'opened':
      case 'reopened':
        return await _checkForLabelsAndTests(event);
      case 'labeled':
        if (event.pullRequest.mergeable == true) {
          await _onLabeledPullRequest(event);
        }
        break;
      case 'closed':
        await _cancelLuci(event.repository.name, event.number);
        break;
      case 'unlabeled':
        if (!await _checkForCqLabel(event.repository.slug(), event.number)) {
          await _cancelLuci(event.repository.name, event.number);
        }
        break;
      case 'assigned':
      case 'unassigned':
      case 'review_requested':
      case 'review_request_removed':
      case 'edited':
      case 'ready_for_review':
      case 'locked':
      case 'unlocked':
    }
    return Body.empty;
  }

  Future<void> _onLabeledPullRequest(PullRequestEvent event) async {
    if (await _checkForCqLabel(event.repository.slug(), event.number)) {
      _scheduleLuci(
        number: event.number,
        repositoryName: event.repository.name,
      );
    }
  }

  Future<List<Build>> _buildsForRepositoryAndPr(
    String repositoryName,
    int number,
    BuildBucketClient buildBucketClient,
    ServiceAccountInfo serviceAccount,
  ) async {
    final SearchBuildsResponse response = await buildBucketClient.searchBuilds(
      SearchBuildsRequest(
        predicate: BuildPredicate(
          builderId: BuilderId(
            project: repositoryName,
            bucket: 'prod',
          ),
          createdBy: serviceAccount.email,
          tags: <String, List<String>>{
            'pr': <String>[number.toString()],
          },
        ),
      ),
    );
    buildBucketClient.close();
    return response.builds;
  }

  Future<bool> _scheduleLuci({
    int number,
    String repositoryName,
    bool force = false,
  }) async {
    assert(force != null);
    if (repositoryName != 'flutter' || repositoryName != 'engine') {
      throw BadRequestException('Repository $repositoryName is not supported by this service.');
    }
    final ServiceAccountInfo serviceAccount = await config.deviceLabServiceAccount;
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      clientContext,
      serviceAccount: serviceAccount,
    );
    bool shouldScheduleBuilds = force;
    if (!shouldScheduleBuilds) {
      final List<Build> builds = await _buildsForRepositoryAndPr(
        repositoryName,
        number,
        buildBucketClient,
        serviceAccount,
      );
      shouldScheduleBuilds = builds != null && builds.isNotEmpty;
    }

    if (shouldScheduleBuilds) {
      final Map<String, List<String>> builders = await config.luciBuilders;
      for (String builder in builders[repositoryName]) {
        final BuilderId builderId = BuilderId(
          project: repositoryName,
          bucket: 'prod',
          builder: builder,
        );
        await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
          builderId: builderId,
          experimental: Trinary.yes,
          tags: <String, List<String>>{
            'pr': <String>[number.toString()],
            'github_link': <String>['https://github.com/flutter/$repositoryName/pulls/$number'],
          },
          properties: <String, String>{
            'git_url': 'https://github.com/flutter/$repositoryName',
            'git_ref': 'pulls/$number/head',
          },
        ));
      }
    }
    buildBucketClient.close();
    return shouldScheduleBuilds;
  }

  /// Checks the issue in the given repository for `config.cqLabelName`.
  Future<bool> _checkForCqLabel(RepositorySlug slug, int issueNumber) async {
    final GitHub gitHubClient = await config.createGitHubClient();
    try {
      final String cqLabelName = await config.cqLabelName;
      await for (IssueLabel label in gitHubClient.issues.listLabelsByIssue(slug, issueNumber)) {
        if (label.name == cqLabelName) {
          return true;
        }
      }
    } finally {
      gitHubClient.dispose();
    }
    return false;
  }

  Future<void> _cancelLuci(String repositoryName, int number) async {
    if (repositoryName != 'flutter' && repositoryName != 'engine') {
      throw BadRequestException('This service does not support repository $repositoryName');
    }
    final ServiceAccountInfo serviceAccount = await config.deviceLabServiceAccount;
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      clientContext,
      serviceAccount: serviceAccount,
    );
    final List<Build> builds = await _buildsForRepositoryAndPr(
      repositoryName,
      number,
      buildBucketClient,
      serviceAccount,
    );
    if (builds == null) {
      return;
    }
    final List<Request> requests = <Request>[];
    for (Build build in builds) {
      requests.add(
        Request(
          cancelBuild: CancelBuildRequest(id: build.id, summaryMarkdown: 'No longer needed.'),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
  }

  Future<Body> _checkForLabelsAndTests(PullRequestEvent event) async {
    if (event.repository.fullName.toLowerCase() == 'flutter/flutter') {
      final GitHub gitHubClient = await config.createGitHubClient();
      try {
        await _checkBaseRef(gitHubClient, event);
        await _applyLabels(gitHubClient, event);
      } finally {
        gitHubClient.dispose();
      }
    }
    return Body.empty;
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
}
