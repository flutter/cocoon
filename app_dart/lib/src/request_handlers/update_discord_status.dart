// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/build_status_snapshot.dart';
import '../request_handling/exceptions.dart';
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
      throw const BadRequestException('Only ?repo=flutter is supported');
    }

    final response = await super.createResponse();

    await recordStatus(response);

    return Body.forJson(response);
  }

  BuildStatusSnapshot _getDefaultAssumedPassing() {
    return BuildStatusSnapshot(
      createdOn: _now(),
      failingTasks: [],
      status: BuildStatus.success,
    );
  }

  /// Sends tree status updates to discord when they change from what was
  /// last sent.
  Future<void> recordStatus(rpc_model.BuildStatusResponse status) async {
    // Fetch the previous status: if it doesn't exist, assume it was passing.
    final firestore = await config.createFirestoreService();

    // Create a new status.
    final latest = BuildStatusSnapshot(
      createdOn: _now(),
      failingTasks: status.failingTasks,
      status: switch (status.buildStatus) {
        rpc_model.BuildStatus.success => BuildStatus.success,
        rpc_model.BuildStatus.failure => BuildStatus.failure,
      },
    );

    // Check against the previous, if any.
    final previous =
        await BuildStatusSnapshot.getLatest(firestore) ??
        _getDefaultAssumedPassing();

    final diff = latest.diffContents(previous);

    // Record the new status.
    if (diff.isDifferent) {
      log.debug('[update_discord_status] status changed: $latest');
      await firestore.createDocument(
        latest,
        collectionId: BuildStatusSnapshot.metadata.collectionId,
      );
    } else {
      return;
    }

    final message = StringBuffer('flutter/flutter is ');
    if (latest.status == BuildStatus.success) {
      message.writeln('now :green_circle:!');
    } else if (diff.newStatus != null) {
      message.writeln('now :red_circle:!');
    } else {
      message.writeln('still :red_circle:!');
    }

    final duration = latest.createdOn.difference(previous.createdOn);
    message.writeln('It has been ${duration.inMinutes} minutes');

    final details = StringBuffer();
    if (diff.nowFailing.isNotEmpty) {
      details.writeln('Now failing:');
      details.writeln('```');
      details.writeln(diff.nowFailing.join(', '));
      details.writeln('```');
    }

    if (diff.nowPassing.isNotEmpty) {
      details.writeln('Now passing:');
      details.writeln('```');
      details.writeln(diff.nowPassing.join(', '));
      details.writeln('```');
    }

    log.info('[update_discord_status] posting to discord: $message');

    if (message.length + details.length > 1000) {
      // Be conservative.
      message.writeln(':cry: ${latest.failingTasks.length} tasks are failing');
    } else {
      message.writeln(details);
    }

    await _discord.postTreeStatusMessage('$message');
  }
}
