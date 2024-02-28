// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import '../foundation/providers.dart';
import 'log.dart';

part 'discord_notification.g.dart';

class DiscordNotification {

  DiscordNotification({required this.targetUri, Map<String, String>? headers}) {
    this.headers = headers ??= defaultHeaders;
  }

  Uri? targetUri;
  Map<String, String>? headers;
  // final Uri discordTreeStatus = Uri(host: 'https://discord.com/api/webhooks/895769852046893097/PKZyS2QKY--pH0wQIx2ThUegHcdh5yoSsZCFqJn94e8aP7kcxIaAKuDY7ztUweZtf2dE');
  Map<String, String> defaultHeaders = <String, String>{
    'content-type': 'application/json',
  };

  final HttpProvider httpProvider = Providers.freshHttpClient;

  // void notifyOfRevert(String initiatingAuthor, String originalPrUrl, String revertPrUrl, String reasonForRevert) async {
  void notifyDiscordChannelWebhook(String jsonMessageString) async {
     final http.Client client = httpProvider();

    final http.Response response = await client.post(
      targetUri!,
      headers: defaultHeaders,
      body: jsonMessageString,
    );

    log.info('discord webhook status: ${response.statusCode}');
    log.info('discord webhook response body: ${response.body}');
  }

  // String _formatMessage(String initiatingAuthor, String originalPrUrl, String revertPrUrl, String reasonForRevert) {
  //   return '''
  //     {
  //       "content": "Pull Request $originalPrUrl has been reverted by $initiatingAuthor.\nReason: $reasonForRevert.\nRevert link: $revertPrUrl",
  //       "username": "autosubmit[bot]"
  //     }
  //   ''';
  // }
}

@JsonSerializable()
class Message {
  Message({this.content, this.username, this.avatarUrl});

  String? content;
  String? username;
  // avatar_url
  @JsonKey(name: 'avatar_url')
  String? avatarUrl;

  factory Message.fromJson(Map<String, dynamic> input) =>
      _$MessageFromJson(input);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}