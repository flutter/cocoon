import 'dart:convert';

import 'package:auto_submit/requests/github_pull_request_event.dart';
import 'package:test/test.dart';

import 'github_webhook_test_data.dart';

void main() {
  test('test', () {
    final String jsonGithubWebhookEvent = generateWebhookEvent();
    final GithubPullRequestEvent githubEventMessage = GithubPullRequestEvent.fromJson(jsonDecode(jsonGithubWebhookEvent) as Map<String, dynamic>);
    
  });
}