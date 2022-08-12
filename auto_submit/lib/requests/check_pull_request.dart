// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/service/approver_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:shelf/shelf.dart';
import '../service/validation_service.dart';

import '../request_handling/authentication.dart';
import '../request_handling/pubsub.dart';
import '../service/config.dart';

import '../service/log.dart';
import '../server/authenticated_request_handler.dart';

/// Handler for processing pull requests with 'autosubmit' label.
///
/// For pull requests where an 'autosubmit' label was added in pubsub,
/// check if the pull request is mergable.
class CheckPullRequest extends AuthenticatedRequestHandler {
  const CheckPullRequest({
    required Config config,
    required CronAuthProvider cronAuthProvider,
    this.approverProvider = ApproverService.defaultProvider,
    this.pubsub = const PubSub(),
  }) : super(config: config, cronAuthProvider: cronAuthProvider);

  final PubSub pubsub;
  final ApproverServiceProvider approverProvider;

  static const int kPullMesssageBatchSize = 100;

  @override
  Future<Response> get() async {
    // Loops [config.kPubsubPullNumber] times to try pulling/processing as many
    // messages as possible.
    for (int i = 0; i < config.kPubsubPullNumber; i++) {
      await checkPullRequest();
    }
    return Response.ok('Finished processing changes');
  }

  /// Pulls Pub/Sub messages and processes pull requests.
  Future<void> checkPullRequest() async {
    final Set<int> processingLog = <int>{};
    final ApproverService approver = approverProvider(config);
    final pub.PullResponse pullResponse = await pubsub.pull('auto-submit-queue-sub', kPullMesssageBatchSize);
    final List<pub.ReceivedMessage>? receivedMessages = pullResponse.receivedMessages;
    if (receivedMessages == null) {
      log.info('There are no requests in the queue');
      return;
    }
    log.info('Processing ${receivedMessages.length} messages');
    ValidationService validationService = ValidationService(config);
    final List<Future<void>> futures = <Future<void>>[];

    for (pub.ReceivedMessage message in receivedMessages) {
      final String messageData = message.message!.data!;
      final rawBody = json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
      final PullRequest pullRequest = PullRequest.fromJson(rawBody);
      log.info('Processing message ackId: ${message.ackId}');
      log.info('Processing mesageId: ${message.message!.messageId}');
      log.info('Processing PR: $rawBody');
      if (processingLog.contains(pullRequest.number)) {
        // Ack duplicate.
        log.info('Ack the duplicated message : ${message.ackId!}.');
        await pubsub.acknowledge('auto-submit-queue-sub', message.ackId!);
        continue;
      } else {
        await approver.approve(pullRequest);
        log.info('Approved pull request: $rawBody');
        processingLog.add(pullRequest.number!);
      }
      futures.add(validationService.processMessage(pullRequest, message.ackId!, pubsub));
    }
    await Future.wait(futures);
  }
}
