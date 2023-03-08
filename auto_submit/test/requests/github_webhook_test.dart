// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_submit/requests/github_webhook.dart';
import 'package:auto_submit/requests/exceptions.dart';
import 'package:crypto/crypto.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../service/merge_update_service_test_data.dart';

void main() {
  group('Check Webhook', () {
    late Request req;
    late GithubWebhook githubWebhook;
    const String keyString = 'not_a_real_key';
    final FakeConfig config = FakeConfig(webhookKey: keyString);
    final FakePubSub pubsub = FakePubSub();
    late Map<String, String> validHeader;
    late Map<String, String> inValidHeader;

    String getHmac(Uint8List list, Uint8List key) {
      final Hmac hmac = Hmac(sha1, key);
      return hmac.convert(list).toString();
    }

    setUp(() {
      githubWebhook = GithubWebhook(config: config, pubsub: pubsub);
    });

    test('Call handler to handle the post request', () async {
      final Uint8List body = utf8.encode(generateWebhookEvent()) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      validHeader = <String, String>{'X-Hub-Signature': 'sha1=$hmac', 'X-GitHub-Event': 'pull_request',};
      req = Request('POST', Uri.parse('http://localhost/'), body: generateWebhookEvent(), headers: validHeader);
      final Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      final reqBody = json.decode(resBody) as Map<String, dynamic>;
      final List<IssueLabel> labels = PullRequest.fromJson(reqBody['pull_request'] as Map<String, dynamic>).labels!;
      expect(labels[0].name, 'cla: yes');
      expect(labels[1].name, 'autosubmit');
    });

    test('Rejects invalid hmac', () async {
      inValidHeader = <String, String>{'X-GitHub-Event': 'pull_request', 'X-Hub-Signature': 'bar'};
      req = Request('POST', Uri.parse('http://localhost/'), body: 'Hello, World!', headers: inValidHeader);
      await expectLater(githubWebhook.post(req), throwsA(isA<Forbidden>()));
    });

    test('Rejects missing headers', () async {
      req = Request('POST', Uri.parse('http://localhost/'), body: generateWebhookEvent());
      await expectLater(githubWebhook.post(req), throwsA(isA<BadRequestException>()));
    });

    test('Reject pull request with no labels', () async {
      final Uint8List body = utf8.encode(generateWebhookEvent(
        labelName: 'draft',
        autosubmitLabel: 'validate:test',
      )) as Uint8List;
      final Response response = await githubWebhook.processPullRequest(body);
      expect(response.statusCode, 200);
      expect(await response.readAsString(), GithubWebhook.nonSuccessResponse);
    });

    test('Process comment returns successful', () async {
      final Uint8List requestBody = utf8.encode(commentOnPullRequestPayload) as Uint8List;
      final Response response = await githubWebhook.processComment(requestBody);
      // payload should have information in it and should not be empty.
      expect(response.statusCode, 200);
      expect(await response.readAsString(), isNotEmpty);
    });

    test('Process comment not from pull request fails', () async {
      final Uint8List requestBody = utf8.encode(commentOnNonPullRequestIssuePayload) as Uint8List;
      final Response response = await githubWebhook.processComment(requestBody);
      expect(response.statusCode, 200);
      // Empty payload is considered failure as we would not return the raw text.
      expect(await response.readAsString(), GithubWebhook.nonSuccessResponse);
    });

    test('Process comment is rejected if action is not create', () async {
      final Uint8List requestBody = utf8.encode(nonCreateCommentPayload) as Uint8List;
      final Response response = await githubWebhook.processComment(requestBody);
      expect(response.statusCode, 200);
      // Empty payload is considered failure as we would not return the raw text.
      expect(await response.readAsString(), GithubWebhook.nonSuccessResponse);
    });

    test('Process comment is rejected for missing repository field', () async {
      final Uint8List requestBody = utf8.encode(partialPayload) as Uint8List;
      final Response response = await githubWebhook.processComment(requestBody);
      expect(response.statusCode, 200);
      // Empty payload is considered failure as we would not return the raw text.
      expect(await response.readAsString(), GithubWebhook.nonSuccessResponse);
    });

    test('Validate issue comment detects MEMBER Correctly', () {
      final IssueComment issueComment = IssueComment(body: '@autosubmit:merge', authorAssociation: 'MEMBER',);
      final bool processed = githubWebhook.isValidMergeUpdateComment(issueComment);
      expect(processed, isTrue);
    });

    test('Validate issue comment detects non MEMBER correctly', () {
      final IssueComment issueComment = IssueComment(body: '@autosubmit:merge', authorAssociation: 'CONTRIBUTOR',);
      final bool processed = githubWebhook.isValidMergeUpdateComment(issueComment);
      expect(processed, isFalse);
    });

    test('Validate issue comment detects comment format correctly', () {
      final IssueComment issueComment = IssueComment(body: '@autosubmit :   merge', authorAssociation: 'MEMBER',);
      final bool processed = githubWebhook.isValidMergeUpdateComment(issueComment);
      expect(processed, isTrue);
    });

    test('Validate issue comment detects comment format correctly with other text', () {
      final IssueComment issueComment = IssueComment(body: '@autosubmit:mergewith text', authorAssociation: 'MEMBER',);
      final bool processed = githubWebhook.isValidMergeUpdateComment(issueComment);
      expect(processed, isTrue);
    });

    test('Validate pull request requirements are detected correctly', () {
      final IssuePullRequest pullRequest = IssuePullRequest();
      final Issue issue = Issue(pullRequest: pullRequest);
      final bool processed = githubWebhook.isValidPullRequestIssue(issue);
      expect(processed, isTrue);
    });

    test('Validate invalid pull request requirements are detexted correctly', () {
      final Issue issue = Issue();
      final bool processed = githubWebhook.isValidPullRequestIssue(issue);
      expect(processed, isFalse);
    });
  });
}
