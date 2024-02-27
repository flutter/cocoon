// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;

import '../foundation/providers.dart';
import 'log.dart';

class DiscordNotification {
  
  final Uri discordUri = Uri(host: 'https://discord.com/api/webhooks/895769852046893097/PKZyS2QKY--pH0wQIx2ThUegHcdh5yoSsZCFqJn94e8aP7kcxIaAKuDY7ztUweZtf2dE');
  Map<String, String> headers = <String, String>{
    'content-type': 'application/json',
  };

  DiscordNotification();

  final HttpProvider httpProvider = Providers.freshHttpClient;

  void notifyOfRevert(String initiatingAuthor, String originalPrUrl, String revertPrUrl, String reasonForRevert) async {
     final http.Client client = httpProvider();

    final http.Response response = await client.post(
      discordUri,
      headers: headers,
      body: _formatMessage(initiatingAuthor, originalPrUrl, revertPrUrl, reasonForRevert),
    );

    log.info('discord webhook status: ${response.statusCode}');
    log.info('discord webhook response body: ${response.body}');
  }

  String _formatMessage(String initiatingAuthor, String originalPrUrl, String revertPrUrl, String reasonForRevert) {
    return '''
      {
        "content": "Pull Request $originalPrUrl has been reverted by $initiatingAuthor.\nReason: $reasonForRevert.\nRevert link: $revertPrUrl",
        "username": "autosubmit[bot]"
      }
    ''';
  }
}