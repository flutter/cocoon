import 'dart:convert';

import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../model/merge_comment_message.dart';
import '../service/config.dart';
import '../service/log.dart';

final nonSuccessResponse = jsonEncode(<String, String>{});

abstract class EventProcessor {
  factory EventProcessor(
    String eventType,
    Config config,
    PubSub pubSub,
  ) {
    switch (eventType) {
      case 'pull_request':
        return PullRequestProcessor(config, pubSub);
      case 'issue_comment':
        return IssueCommentProcessor(config, pubSub);
      default:
        return NoOpRequestProcessor();
    }
  }

  Future<Response> processEvent(List<int> requestBytes);
}

class NoOpRequestProcessor implements EventProcessor {
  @override
  Future<Response> processEvent(List<int> requestBytes) async {
    return Response.ok(nonSuccessResponse);
  }
}

class PullRequestProcessor implements EventProcessor {
  PullRequestProcessor(this.config, this.pubSub);

  final Config config;
  final PubSub pubSub;

  @override
  Future<Response> processEvent(List<int> requestBytes) async {
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
      await pubSub.publish(
        'auto-submit-queue',
        pullRequest,
      );
      return Response.ok(rawBody);
    }

    return Response.ok(nonSuccessResponse);
  }
}

class IssueCommentProcessor implements EventProcessor {
  IssueCommentProcessor(this.config, this.pubSub);

  final Config config;
  final PubSub pubSub;

  /// Process a github issue comment that was passed to this webhook.
  ///
  /// In order for the comment to be processed it must be a newly created
  /// comment, and be a comment left on a pull request. The author of the
  /// comment must also be a MEMBER or OWNER of the repository.
  @override
  Future<Response> processEvent(List<int> requestBytes) async {
    log.info('Processing event...');
    final String rawPayload = utf8.decode(requestBytes);
    final Map<String, dynamic> jsonPayload = json.decode(rawPayload) as Map<String, dynamic>;

    log.info('payload = $jsonPayload');

    // Do not process edited comments.
    if (jsonPayload.containsKey('action') && jsonPayload['action'] != 'created') {
      log.info('Ignoring comment with non "created" action');
      return Response.ok(nonSuccessResponse);
    } else {
      log.info('Action = created.');
    }

    // Check for keys so we do not blow up. We must have all three of these.
    if (!jsonPayload.containsKey('issue') ||
        !jsonPayload.containsKey('comment') ||
        !jsonPayload.containsKey('repository')) {
      log.info('Comment payload does not contain the required keys, "issue," "comment," and "repository"');
      return Response.ok(nonSuccessResponse);
    } else {
      log.info('All keys present.');
    }

    // The issue has the repo information we need and the issue_comment has the
    // request being made and the author association.
    final Issue issue = Issue.fromJson(jsonPayload['issue'] as Map<String, dynamic>);
    final IssueComment issueComment = IssueComment.fromJson(jsonPayload['comment'] as Map<String, dynamic>);
    final Repository repository = Repository.fromJson(jsonPayload['repository'] as Map<String, dynamic>);

    log.info('${issue.pullRequest}');
    log.info('${issueComment.body}');
    log.info(repository.fullName);

    if (isValidPullRequestIssue(issue) && isValidMergeUpdateComment(issueComment)) {
      log.info('Found a comment requesting a merge update.');

      // Since we do not need all the information we can construct what we need.
      final MergeCommentMessage mergeCommentMessage = MergeCommentMessage(
        issue: issue,
        comment: issueComment,
        repository: repository,
      );

      await pubSub.publish(
        'auto-submit-comments',
        mergeCommentMessage,
      );
      return Response.ok(rawPayload);
    } else {
      log.warning(
          'The comment was not on a pull request or the author does not have the authority to request a merge update.');
    }

    return Response.ok(nonSuccessResponse);
  }

  /// Verify that this is a pull request issue.
  bool isValidPullRequestIssue(Issue issue) {
    log.info(issue.pullRequest);
    return issue.pullRequest != null;
  }

  /// Verify that the comment being processed was written by a member of the
  /// google team.
  bool isValidMergeUpdateComment(IssueComment issueComment) {
    // TODO remove contributor as I am not a member or owner and needed to test this.
    return issueComment.body != null && Config.regExpMergeMethod.hasMatch(issueComment.body!);
  }
}
