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

  if (request.headers.value('X-GitHub-Event') == null || request.headers.value('X-GitHub-Signature') == null) {
    await request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Missing required headers.')
      ..close();
    return;
  }

  final List<int> requestBytes = await request.expand((_) => _).toList();
  final String hmacSignature = request.headers.value('X-GitHub-Signature');
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
    if (event.pullRequest.base.ref != 'master') {
      final String body = await _getWrongBaseComment(config, event.pullRequest.base.ref);
      final RepositorySlug slug = event.repository.slug();
      final GitHub githubClient = await config.gitHubClient;

      await githubClient.pullRequests.edit(slug, event.number, base: 'master');
      await githubClient.issues.createComment(slug, event.number, body);
      githubClient.dispose();
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
  final List<int> decodedRequestBytes = hmac.convert(requestBody).bytes;
  final String bodySignature = 'sha1=${hexEncodeHmac(decodedRequestBytes)}';
  return bodySignature == signature;
}

/// Converts an HMAC signature to the format that GitHub uses in headers.
String hexEncodeHmac(List<int> bytes) {
  final StringBuffer hexString = StringBuffer();
  for (int byte in bytes) {
    hexString.write(byte.toRadixString(16));
  }
  return hexString.toString();
}
