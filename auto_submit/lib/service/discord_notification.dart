import 'dart:convert';

import 'package:http/http.dart' as http;

import '../foundation/providers.dart';
import 'access_client_provider.dart';
import 'log.dart';

class DiscordNotification {
  /*
    curl -X POST \
    -H 'content-type: application/json' \
    -d '{"content": "Testing webhook.", "username": "autosubmit"}' \
    https://discord.com/api/webhooks/1026618310458081290/99V7abNhiKyJHZHn_RrSs0mJvxTg1aJYfhSlM8tTn6fQ86A0Jf1DL1Yp4I2NqZnbQUt3
  */
  Uri DISCORD_URI = Uri(host: 'https://discord.com/api/webhooks/895769852046893097/PKZyS2QKY--pH0wQIx2ThUegHcdh5yoSsZCFqJn94e8aP7kcxIaAKuDY7ztUweZtf2dE');
  Map<String, String> headers = <String, String>{
    'content-type': 'application/json',
  };

  DiscordNotification();

  final HttpProvider httpProvider = Providers.freshHttpClient;

  void notifyOfRevert(String prUrl) async {
     final http.Client client = httpProvider();
    // TODO(KristinBi): Track the installation id by repo. https://github.com/flutter/flutter/issues/100808
    final http.Response response = await client.post(
      DISCORD_URI,
      headers: headers,
      body: _formatMessage(prUrl),
    );
    final List<Map<String, dynamic>> list = (json.decode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  String _formatMessage(String prUrl) {
    return '''
      {
        "content": "$prUrl has been reverted.",
        "username": "Revert-bot"
      }
    ''';
  }
}