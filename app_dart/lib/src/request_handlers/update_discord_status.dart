// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_server/logging.dart';
import 'package:googleapis/firestore/v1.dart' show Document, Value;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../service/discord_service.dart' show DiscordService;

@immutable
final class UpdateDiscordStatus extends GetBuildStatus {
  const UpdateDiscordStatus({
    required super.config,
    required super.buildStatusService,
    required DiscordService discord,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _discord = discord,
       _now = now;

  final DiscordService _discord;
  final DateTime Function() _now;

  static const _kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    // For now, limit these to flutter/flutter only
    if (request!.uri.queryParameters[_kRepoParam] != 'flutter') {
      return Body.forJson(const <String, dynamic>{});
    }

    final response = await super.createResponse();

    await recordStatus(response);

    return Body.forJson(response);
  }

  /// Sends tree status updates to discord when they change from what was
  /// last sent.
  Future<void> recordStatus(rpc_model.BuildStatusResponse status) async {
    final statusString =
        status.buildStatus == rpc_model.BuildStatus.success
            ? 'flutter/flutter is :green_circle:!'
            : 'flutter/flutter is :red_circle:! Failing tasks: '
                '${status.failingTasks.join(', ')}';

    final firestore = await config.createFirestoreService();
    final lastDocs = await firestore.query(
      'last_build_status',
      <String, Object>{},
      limit: 1,
      orderMap: {'createTimestamp': kQueryOrderDescending},
    );

    if (lastDocs.isEmpty ||
        lastDocs.first.fields?['status']?.stringValue != statusString) {
      log.debug('[update_discord_status] status changed');
      await firestore.createDocument(
        Document(
          fields: <String, Value>{
            'status': Value(stringValue: statusString),
            'createTimestamp': Value(
              timestampValue: _now().toUtc().toIso8601String(),
            ),
          },
        ),
        collectionId: 'last_build_status',
      );

      final discordMessage =
          statusString.length < 1000
              ? statusString
              : '${statusString.substring(0, 1000)}... things appear to be very broken right now. :cry:';

      log.info('[update_discord_status] posting to discord: $discordMessage');
      await _discord.postTreeStatusMessage(discordMessage);
    }
  }
}
