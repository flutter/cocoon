// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:http/http.dart' show Client;
import 'package:meta/meta.dart';
import 'package:truncate/truncate.dart';

import 'config.dart' show Config;

enum DiscordStatus { ok, failed }

interface class DiscordService {
  DiscordService({
    required Config config, //
    @visibleForTesting Client? client,
  }) : _config = config,
       _client = client ?? Client();

  /// The global configuration of this AppEngine server.
  final Config _config;

  /// A way to POST to discord.
  final Client _client;

  /// Post a message to the #tree-status-🚦 channel
  Future<DiscordStatus> postTreeStatusMessage(String message) async {
    final discordMessage = truncate(message, 2000);
    final discordResponse = await _client.post(
      Uri.parse(await _config.discordTreeStatusWebhookUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'content': discordMessage}),
    );
    if (discordResponse.statusCode >= 400) {
      log.warn(
        '[discord_service] failed to post tree-status to discord: ${discordResponse.statusCode} / ${discordResponse.body}. Status: $discordMessage',
      );
      return DiscordStatus.failed;
    }
    log.debug(
      '[discord_service] posted message to discord: ${discordResponse.statusCode} / ${discordResponse.body}. Status: $discordMessage',
    );
    return DiscordStatus.ok;
  }
}
