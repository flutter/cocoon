// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:cocoon_server/logging.dart';

import '../foundation/providers.dart';

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
