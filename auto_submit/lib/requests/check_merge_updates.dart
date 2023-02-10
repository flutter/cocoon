import 'dart:convert';

import 'package:auto_submit/server/authenticated_request_handler.dart';
import 'package:auto_submit/service/merge_update_service.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;

import '../request_handling/pubsub.dart';

import '../service/log.dart';

class CheckMergeUpdates extends AuthenticatedRequestHandler {
  const CheckMergeUpdates({
    required super.config,
    required super.cronAuthProvider,
    this.pubsub = const PubSub(),
  });

  final PubSub pubsub;
  static const int pullMesssageBatchSize = 100;
  static const int pubsubPullNumber = 5;
  
  @override
  Future<Response> get() async {
    final Set<int> processingLog = <int>{};
    final List<pub.ReceivedMessage> messageList = await pullMessages();
    if (messageList.isEmpty) {
      log.info('No messages are pulled.');
      return Response.ok('No messages are pulled.');
    }

    log.info('Processing ${messageList.length} messages');
    
    final List<Future<void>> futures = <Future<void>>[];
    final MergeUpdateService mergeUpdateService = MergeUpdateService(config);

    for (pub.ReceivedMessage message in messageList) {
      final String messageData = message.message!.data!;
      final rawBody = json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
      
      final IssueComment issueComment = IssueComment.fromJson(rawBody['comment'] as Map<String, dynamic>);
      final Issue issue = Issue.fromJson(rawBody['issue'] as Map<String, dynamic>);
      final Repository repository = Repository.fromJson(rawBody['repository'] as Map<String, dynamic>);
      final RepositorySlug slug = repository.slug();

      log.info('Processing message ackId: ${message.ackId}');
      log.info('Processing mesageId: ${message.message!.messageId}');
      log.info('Processing comment: $rawBody');

      if (processingLog.contains(issueComment.id)) {
        log.info('Ack the duplicated message : ${message.ackId!}.');
        await pubsub.acknowledge('auto-submit-comment-sub', message.ackId!);
        continue;
      } else {
        processingLog.add(issueComment.id!);
      }
      futures.add(mergeUpdateService.processMessage(slug, issue.number, issueComment, message.ackId!, pubsub));
    }
    await Future.wait(futures);
    return Response.ok('Finished processing changes');
  }

  /// Pulls queued Pub/Sub messages.
  ///
  /// Pub/Sub pull request API doesn't guarantee returning all messages each time. This
  /// loops to pull `kPubsubPullNumber` times to try covering all queued messages.
  Future<List<pub.ReceivedMessage>> pullMessages() async {
    final Map<String, pub.ReceivedMessage> messageMap = <String, pub.ReceivedMessage>{};
    for (int i = 0; i < pubsubPullNumber; i++) {
      final pub.PullResponse pullResponse = await pubsub.pull('auto-submit-comment-sub', pullMesssageBatchSize);
      final List<pub.ReceivedMessage>? receivedMessages = pullResponse.receivedMessages;
      if (receivedMessages == null) {
        continue;
      }
      for (pub.ReceivedMessage message in receivedMessages) {
        final String messageId = message.message!.messageId!;
        messageMap[messageId] = message;
      }
    }
    return messageMap.values.toList();
  }
}
