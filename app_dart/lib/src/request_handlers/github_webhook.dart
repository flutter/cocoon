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
import '../github.dart';
import '../request_handling/request_handler.dart';

@immutable
class GithubWebhook extends RequestHandler {
  const GithubWebhook(Config config) : super(config: config);

  @override
  Future<void> post(HttpRequest request, HttpResponse response) async {
    if (request.headers.value('X-GitHub-Event') != 'pull_request' ||
        request.headers.value('X-Hub-Signature') == null) {
      response
        ..statusCode = HttpStatus.badRequest
        ..write('Missing required headers.');
      await response.close();
      return;
    }

    final List<int> requestBytes = await request.expand((_) => _).toList();
    final String hmacSignature = request.headers.value('X-Hub-Signature');
    if (!await _validateRequest(hmacSignature, requestBytes)) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }

    try {
      final String stringRequest = utf8.decode(requestBytes);
      final PullRequestEvent event = await getPullRequest(stringRequest);
      if (event == null) {
        response.statusCode = HttpStatus.badRequest;
        await response.close();
        return;
      }
      if (event.action != 'opened' && event.action != 'reopened') {
        response.statusCode = HttpStatus.ok;
        await response.close();
        return;
      }
      final GitHub gitHubClient = await config.createGitHubClient();
      try {
        await _checkBaseRef(gitHubClient, event);
        await _applyLabels(gitHubClient, event);
      } finally {
        gitHubClient.dispose();
      }
      response.statusCode = HttpStatus.ok;
      await response.close();
    } on FormatException {
      response.statusCode = HttpStatus.badRequest;
      await response.close();
      return;
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
}
