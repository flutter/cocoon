// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/github_status.dart';

/// See https://www.githubstatus.com/api
Future<GitHubStatus> fetchGitHubStatus({http.Client client}) async {
  client ??= http.Client();
  final Map<String, dynamic> fetchedStatus = await _getStatusBody(client);
  if (fetchedStatus == null) {
    return null;
  }
  final Map<String, dynamic> status = fetchedStatus['status'];
  if (status == null) {
    return null;
  }
  return GitHubStatus(status: status['description'], indicator: status['indicator']);
}

Future<dynamic> _getStatusBody(http.Client client) async {
  try {
    final http.Response response = await client.get('https://kctbh9vrtdwd.statuspage.io/api/v2/status.json');
    final String body = response?.body;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  } catch (error) {
    print('Error fetching GitHub status: $error');
    return null;
  }
}
