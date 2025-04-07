// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' show Document, Value;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/typedefs.dart' show HttpClientProvider;
import '../service/build_status_provider.dart';

@immutable
base class GetBuildStatus extends RequestHandler<Body> {
  const GetBuildStatus({
    required super.config,
    required BuildStatusService buildStatusService,
    @visibleForTesting DateTime Function() now = DateTime.now,
    @visibleForTesting HttpClientProvider httpClientProvider = http.Client.new,
  }) : _buildStatusService = buildStatusService,
       _now = now,
       _httpClientProvider = httpClientProvider;

  final HttpClientProvider _httpClientProvider;
  final BuildStatusService _buildStatusService;
  final DateTime Function() _now;

  static const _kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final response = await createResponse();
    return Body.forJson(response);
  }

  @protected
  Future<rpc_model.BuildStatusResponse> createResponse() async {
    final repoName = request!.uri.queryParameters[_kRepoParam] ?? 'flutter';
    final slug = RepositorySlug('flutter', repoName);
    final status = (await _buildStatusService.calculateCumulativeStatus(slug))!;

    await maybeNotifyDiscord(status);

    return rpc_model.BuildStatusResponse(
      buildStatus:
          status.succeeded
              ? rpc_model.BuildStatus.success
              : rpc_model.BuildStatus.failure,
      failingTasks: status.failedTasks,
    );
  }

  /// Sends tree status updates to discord when they change from what was
  /// last sent.
  Future<void> maybeNotifyDiscord(BuildStatus status) async {
    final statusString =
        status.succeeded
            ? 'flutter/flutter is :green_circle:!'
            : 'flutter/flutter is :red_circle:! Failing tasks: '
                '${status.failedTasks.join(', ')}';

    final firestore = await config.createFirestoreService();
    final lastDocs = await firestore.query(
      'last_build_status',
      <String, Object>{},
      limit: 1,
      orderMap: {'createTimestamp	': kQueryOrderDescending},
    );

    if (lastDocs.isEmpty ||
        lastDocs.first.fields?['status']?.stringValue != statusString) {
      await firestore.createDocument(
        Document(
          fields: <String, Value>{
            'status': Value(stringValue: statusString),
            'createTimestamp': Value(timestampValue: _now().toIso8601String()),
          },
        ),
        collectionId: 'last_build_status',
      );

      final discordMessage =
          statusString.length < 1000
              ? statusString
              : '${statusString.substring(0, 1000)}... things appear to be very broken right now. :cry:';

      final client = _httpClientProvider();
      final discordResponse = await client.post(
        Uri.parse(await config.discordTreeStatusWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': discordMessage}),
      );
      if (discordResponse.statusCode != 200) {
        log.warn(
          'failed to post tree-status to discord: ${discordResponse.statusCode} / ${discordResponse.body}. Status: $discordMessage',
        );
      }
    }
  }
}
