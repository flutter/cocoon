// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/rpc_model.dart';

import '../model/firestore/github_webhook_message.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/firestore.dart';

/// Returns the latest GitHub merge queue hooks from Firestore.
final class MergeQueueHooks extends ApiRequestHandler {
  const MergeQueueHooks({
    required FirestoreService firestore,
    required super.config,
    required super.authenticationProvider,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  static const String kPageSize = 'pageSize';

  @override
  Future<Response> get(Request request) async {
    final email = authContext!.email;
    if (!email.endsWith('@google.com')) {
      throw const Forbidden();
    }

    final pageSize =
        (int.tryParse(request.uri.queryParameters[kPageSize] ?? '') ?? 20)
            .clamp(1, 100);

    final documents = await _firestore.query(
      GithubWebhookMessage.metadata.collectionId,
      <String, Object>{},
      limit: pageSize,
      orderMap: <String, String>{'timestamp': kQueryOrderDescending},
    );

    final messages = [...documents.map(GithubWebhookMessage.fromDocument)];

    final result = <MergeGroupHook>[];
    for (final message in messages) {
      final id = (message.name ?? '').split('/').last;
      final jsonPayload =
          jsonDecode(message.jsonString) as Map<String, dynamic>;
      final mergeGroup = jsonPayload['merge_group'] as Map<String, dynamic>?;
      final headCommit = mergeGroup?['head_commit'] as Map<String, dynamic>?;
      final commitMessage = headCommit?['message'] as String?;

      result.add(
        MergeGroupHook(
          id: id,
          timestamp: message.timestamp.millisecondsSinceEpoch,
          action: jsonPayload['action'] as String,
          headRef: mergeGroup?['head_ref'] as String?,
          headCommitId: headCommit?['id'] as String?,
          headCommitMessage: commitMessage?.split('\n').first,
        ),
      );
    }

    return Response.json(MergeGroupHooks(hooks: result));
  }
}
