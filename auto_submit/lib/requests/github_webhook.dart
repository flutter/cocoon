// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:crypto/crypto.dart';

import '../model/merge_comment_message.dart';
import '../request_handling/pubsub.dart';
import '../service/config.dart';
import '../service/log.dart';
import '../server/request_handler.dart';
import '../requests/exceptions.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook extends RequestHandler {
  const GithubWebhook({
    required super.config,
    this.pubsub = const PubSub(),
  });

  final PubSub pubsub;

  static final nonSuccessResponse = jsonEncode(<String, String>{});

  @override
  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    log.info('Header: $reqHeader');

    // this is how you know what was sent to the webhook.
    final String? gitHubEvent = request.headers['X-GitHub-Event'];

    if (gitHubEvent == null || request.headers['X-Hub-Signature'] == null) {
      throw const BadRequestException('Missing required headers.');
    }

    final List<int> requestBytes = await request.read().expand((_) => _).toList();
    final String? hmacSignature = request.headers['X-Hub-Signature'];
    if (!await _validateRequest(hmacSignature, requestBytes)) {
      throw const Forbidden();
    }

    // Check and process request
    return processEvent(gitHubEvent, requestBytes);
  }

  /// Process and validate the Github events we expect to process with this
  /// webhook.
  Future<Response> processEvent(String githubEvent, List<int> requestBytes) async {
    switch (githubEvent) {
      case 'pull_request':
        return processPullRequest(requestBytes);
      case 'issue_comment':
        return processComment(requestBytes);
      default:
        // We do not recognize the object type yet.
        return Response.ok(nonSuccessResponse);
    }
  }

  /// Process a github issue comment that was passed to this webhook.
  ///
  /// In order for the comment to be processed it must be a newly created
  /// comment, and be a comment left on a pull request. The author of the
  /// comment must also be a MEMBER or OWNER of the repository.
  Future<Response> processComment(List<int> requestBytes) async {
    final String rawPayload = utf8.decode(requestBytes);
    final Map<String, dynamic> jsonPayload = json.decode(rawPayload) as Map<String, dynamic>;

    // Do not process edited comments.
    if (jsonPayload.containsKey('action') && jsonPayload['action'] != 'created') {
      log.info('Ignoring comment with non "created" action');
      return Response.ok(nonSuccessResponse);
    }

    // Check for keys so we do not blow up. We must have all three of these.
    if (!jsonPayload.containsKey('issue') ||
        !jsonPayload.containsKey('comment') ||
        !jsonPayload.containsKey('repository')) {
      log.info('Comment payload does not contain the required keys, "issue," "comment," and "repository"');
      return Response.ok(nonSuccessResponse);
    }

    // The issue has the repo information we need and the issue_comment has the
    // request being made and the author association.
    final Issue issue = Issue.fromJson(jsonPayload['issue'] as Map<String, dynamic>);
    final IssueComment issueComment = IssueComment.fromJson(jsonPayload['comment'] as Map<String, dynamic>);
    final Repository repository = Repository.fromJson(jsonPayload['repository'] as Map<String, dynamic>);

    if (isValidPullRequestIssue(issue) && isValidMergeUpdateComment(issueComment)) {
      log.info('Found a comment requesting a merge update.');

      // Since we do not need all the information we can construct what we need.
      final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
        issue: issue,
        comment: issueComment,
        repository: repository,
      );

      await pubsub.publish('auto-submit-comment-queue', mergeCommentMessage);
      return Response.ok(rawPayload);
    }

    return Response.ok(nonSuccessResponse);
  }

  /// Verify that this is a pull request issue.
  bool isValidPullRequestIssue(Issue issue) {
    return issue.pullRequest != null;
  }

  /// Verify that the comment being processed was written by a member of the
  /// google team.
  bool isValidMergeUpdateComment(IssueComment issueComment) {
    return Config.approvedAuthorAssociations.contains(issueComment.authorAssociation) &&
        (issueComment.body != null && Config.regExpMergeMethod.hasMatch(issueComment.body!));
  }

  /// Process a pull request issue from github.
  ///
  /// The pull request must be a valid pull request and contain the 'autosubmit'
  /// or 'revert' label in order to be processed by this service.
  Future<Response> processPullRequest(List<int> requestBytes) async {
    bool hasAutosubmit = false;
    bool hasRevertLabel = false;
    final String rawBody = utf8.decode(requestBytes);
    final Map<String, dynamic> body = json.decode(rawBody) as Map<String, dynamic>;

    if (!body.containsKey('pull_request') || !((body['pull_request'] as Map<String, dynamic>).containsKey('labels'))) {
      return Response.ok(nonSuccessResponse);
    }

    final PullRequest pullRequest = PullRequest.fromJson(body['pull_request'] as Map<String, dynamic>);

    hasAutosubmit = pullRequest.labels!.any((label) => label.name == Config.kAutosubmitLabel);
    hasRevertLabel = pullRequest.labels!.any((label) => label.name == Config.kRevertLabel);

    if (hasAutosubmit || hasRevertLabel) {
      log.info('Found pull request with auto submit and/or revert label.');
      await pubsub.publish('auto-submit-queue', pullRequest);
      return Response.ok(rawBody);
    }

    return Response.ok(nonSuccessResponse);
  }

  /// Validate that the signature in the github request is valid.
  Future<bool> _validateRequest(
    String? signature,
    List<int> requestBody,
  ) async {
    final String rawKey = await config.getWebhookKey();
    final List<int> key = utf8.encode(rawKey);
    final Hmac hmac = Hmac(sha1, key);
    final Digest digest = hmac.convert(requestBody);
    final String bodySignature = 'sha1=$digest';
    return bodySignature == signature;
  }
}
