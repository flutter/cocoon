// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:http/http.dart' show Client;
import 'package:meta/meta.dart';

import 'config.dart' show Config;

enum DiscordStatus { ok, failed }

interface class DiscordService {
  DiscordService({
    required this.config, //
    @visibleForTesting Client? client,
  }) : _client = client ?? Client();

  /// The global configuration of this AppEngine server.
  final Config config;

  /// A way to POST to discord.
  final Client _client;

  /// Post a message to the #tree-status-🚦 channel
  Future<DiscordStatus> postTreeStatusMessage(String message) async {
    final discordMessage =
        message.length < 2000 ? message : message.substring(0, 2000);

    final discordResponse = await _client.post(
      Uri.parse(await config.discordTreeStatusWebhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'content': discordMessage}),
    );
    if (discordResponse.statusCode != 200) {
      log.warn(
        'failed to post tree-status to discord: ${discordResponse.statusCode} / ${discordResponse.body}. Status: $discordMessage',
      );
      return DiscordStatus.failed;
    }
    return DiscordStatus.ok;
  }
}
