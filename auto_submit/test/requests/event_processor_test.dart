import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_submit/requests/event_processor.dart';
import 'package:auto_submit/requests/event_processor.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../service/merge_update_service_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import 'github_webhook_test_data.dart';

void main() {
  const String keyString = 'not_a_real_key';
  late FakeConfig config;
  late FakePubSub pubSub;

  setUp(() {
    config = FakeConfig(webhookKey: keyString);
    pubSub = FakePubSub();
  });
  group('Abstract event processor test group', () {
    test('Correct event processor is chosen', () {
      EventProcessor eventProcessor = EventProcessor('pull_request', config, pubSub);
      expect(eventProcessor is PullRequestProcessor, isTrue);

      eventProcessor = EventProcessor('issue_comment', config, pubSub);
      expect(eventProcessor is IssueCommentProcessor, isTrue);
    });

    test('Noop Processor chosen on unrecognized type', () {
      final EventProcessor eventProcessor = EventProcessor('eventType', config, pubSub);
      expect(eventProcessor is NoOpRequestProcessor, isTrue);
    });
  });

  group('Pull request event processor test group', () {
    test('Reject pull request with no labels', () async {
      final EventProcessor eventProcessor = EventProcessor('pull_request', config, pubSub);
      final Uint8List body = utf8.encode(generateWebhookEvent(
        labelName: 'draft',
        autosubmitLabel: 'validate:test',
      )) as Uint8List;
      final Response response = await eventProcessor.processEvent(body);
      expect(response.statusCode, 200);
      expect(await response.readAsString(), nonSuccessResponse);
    });
  });

  group('Issue comment event processor test group', () {
    late EventProcessor eventProcessor;

    setUp(() {
      eventProcessor = EventProcessor('issue_comment', config, pubSub);
    });

    test('Process comment returns successful', () async {
      final Uint8List requestBody = utf8.encode(commentOnPullRequestPayload) as Uint8List;
      final Response response = await eventProcessor.processEvent(requestBody);
      // payload should have information in it and should not be empty.
      expect(response.statusCode, 200);
      expect(await response.readAsString(), isNotEmpty);
    });

    test('Process comment not from pull request fails', () async {
      final Uint8List requestBody = utf8.encode(commentOnNonPullRequestIssuePayload) as Uint8List;
      final Response response = await eventProcessor.processEvent(requestBody);
      expect(response.statusCode, 200);
      // Empty payload is considered failure as we would not return the raw text.
      expect(await response.readAsString(), nonSuccessResponse);
    });

    test('Process comment is rejected if action is not create', () async {
      final Uint8List requestBody = utf8.encode(nonCreateCommentPayload) as Uint8List;
      final Response response = await eventProcessor.processEvent(requestBody);
      expect(response.statusCode, 200);
      // Empty payload is considered failure as we would not return the raw text.
      expect(await response.readAsString(), nonSuccessResponse);
    });

    test('Process comment is rejected for missing repository field', () async {
      final Uint8List requestBody = utf8.encode(partialPayload) as Uint8List;
      final Response response = await eventProcessor.processEvent(requestBody);
      expect(response.statusCode, 200);
      // Empty payload is considered failure as we would not return the raw text.
      expect(await response.readAsString(), nonSuccessResponse);
    });
  });
}
