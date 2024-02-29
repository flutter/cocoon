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
  Map<String, String> defaultHeaders = <String, String>{
    'content-type': 'application/json',
  };

  final HttpProvider httpProvider = Providers.freshHttpClient;

  notifyDiscordChannelWebhook(String jsonMessageString) async {
    final http.Client client = httpProvider();

    final http.Response response = await client.post(
      targetUri!,
      headers: defaultHeaders,
      body: jsonMessageString,
    );

    log.info('discord webhook status: ${response.statusCode}');
    log.info('discord webhook response body: ${response.body}');
  }
}

@JsonSerializable()
class Message {
  Message({this.content, this.username, this.avatarUrl});

  String? content;
  String? username;
  // avatar_url
  @JsonKey(name: 'avatar_url', includeIfNull: false)
  String? avatarUrl;

  factory Message.fromJson(Map<String, dynamic> input) => _$MessageFromJson(input);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
