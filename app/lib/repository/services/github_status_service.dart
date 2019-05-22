// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

import '../models/github_status.dart';

/// See https://www.githubstatus.com/api
Future<GithubStatus> fetchGithubStatus() async {
  final Map<String, dynamic> fetchedStatus = await _getStatusBody();
  if (fetchedStatus == null) {
    return null;
  }
  Map<String, dynamic> status = fetchedStatus['status'];
  return GithubStatus()
    ..status = status['description']
    ..indicator = status['indicator'];
}

Future<dynamic> _getStatusBody() async {
  final HttpRequest response = await HttpRequest.request('https://kctbh9vrtdwd.statuspage.io/api/v2/status.json').catchError((Error error) {
    print('Error fetching Github status: $error');
  });

  final String body = response?.response;
  return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
}
