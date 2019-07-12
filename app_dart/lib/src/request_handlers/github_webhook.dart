import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:github/server.dart';

import '../datastore/cocoon_config.dart';
import '../github.dart';

Future<void> githubWebhookPullRequest(Config config, HttpRequest request) async {
  if (request.method != 'POST') {
    await request.response
      ..statusCode = HttpStatus.methodNotAllowed
      ..write('Only POST is Supported')
      ..close();
    return;
  }

  if (request.headers.value('X-GitHub-Event') != 'pull_request' || request.headers.value('X-Hub-Signature') == null) {
    await request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Missing required headers.')
      ..close();
    return;
  }

  final List<int> requestBytes = await request.expand((_) => _).toList();
  final String hmacSignature = request.headers.value('X-Hub-Signature');
  if (!await _validateRequest(config, hmacSignature, requestBytes)) {
    await request.response
      ..statusCode = HttpStatus.forbidden
      ..close();
    return;
  }

  try {
    final String stringRequest = await utf8.decode(requestBytes);
    final PullRequestEvent event = await getPullRequest(stringRequest);
    if (event == null) {
      await request.response
        ..statusCode = HttpStatus.badRequest
        ..close();
      return;
    }
    if (event.action != 'opened' && event.action != 'reopened') {
      await request.response
        ..statusCode = HttpStatus.ok
        ..close();
      return;
    }
    final GitHub gitHubClient = await config.createGitHubClient();
    try {
      await _checkBaseRef(config, gitHubClient, event);
      await _applyLabels(config, gitHubClient, event);
    } finally {
      gitHubClient.dispose();
    }
    await request.response
      ..statusCode = HttpStatus.ok
      ..close();
  } on FormatException {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..close();
    return;
  }
}

Future<void> _applyLabels(Config config, GitHub gitHubClient, PullRequestEvent event) async {
  if (event.sender.login == 'engine-flutter-autoroll') {
    return;
  }
  final RepositorySlug slug = event.repository.slug();
  // TODO(DirectMyFile/github.dart#151): Use event.pullRequests.listFiles API when it's fixed
  List<PullRequestFile> files = await gitHubClient.getJSON<List<dynamic>, List<PullRequestFile>>(
    '/repos/${slug.fullName}/pulls/${event.number}/files',
    convert: (List<dynamic> jsonFileList) =>
        jsonFileList.cast<Map<String, dynamic>>().map(PullRequestFile.fromJSON).toList(),
  );
  bool hasTests = false;
  Set<String> labels = <String>{};
  for (PullRequestFile file in files) {
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

    if (file.filename.startsWith('packages/flutter_test') || file.filename.startsWith('packages/flutter_driver')) {
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
    // TODO(DirectMyFile/github.dart#152): This should be addLabelsToIssue when that is fixed.
    await gitHubClient.postJSON<List<dynamic>, List<IssueLabel>>(
      '/repos/${slug.fullName}/issues/${event.number}/labels',
      body: jsonEncode(labels.toList()),
      convert: (List<dynamic> input) => input.cast<Map<String, dynamic>>().map(IssueLabel.fromJSON).toList(),
    );
  }
  if (!hasTests) {
    final String body = await config.missingTestsPullRequestMessage;
    await gitHubClient.issues.createComment(slug, event.number, body);
  }
}

Future<void> _checkBaseRef(
  Config config,
  GitHub gitHubClient,
  PullRequestEvent event,
) async {
  if (event.pullRequest.base.ref != 'master') {
    final String body = await _getWrongBaseComment(config, event.pullRequest.base.ref);
    final RepositorySlug slug = event.repository.slug();

    await gitHubClient.pullRequests.edit(slug, event.number, base: 'master');
    await gitHubClient.issues.createComment(slug, event.number, body);
  }
}

Future<String> _getWrongBaseComment(Config config, String base) async {
  final String messageTemplate = await config.nonMasterPullRequestMessage;
  return messageTemplate.replaceAll('{{branch}}', base);
}

Future<bool> _validateRequest(
  Config config,
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
