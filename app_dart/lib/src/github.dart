import 'dart:convert';

import 'package:github/server.dart';

Future<PullRequestEvent> getPullRequest(String request) async {
  if (request == null) {
    return null;
  }
  try {
    final PullRequestEvent event = PullRequestEvent.fromJSON(json.decode(request));

    if (event == null) {
      return null;
    }

    return event;
  } on FormatException catch (e) {
    return null;
  }
}
