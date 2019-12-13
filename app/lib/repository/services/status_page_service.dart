// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/status_page_status.dart';

/// StatusPage API used by GitHub and Coveralls.
///
/// See https://doers.statuspage.io/api/v2/.
/// See https://www.githubstatus.com/api.
/// Web version of Coveralls status at https://status.coveralls.io.
Future<StatusPageStatus> fetchStatusPageStatus(String url,
    {http.Client client}) async {
  client ??= http.Client();
  final Map<String, dynamic> fetchedStatus = await _getStatusBody(url, client);
  if (fetchedStatus == null) {
    return null;
  }
  final Map<String, dynamic> status = fetchedStatus['status'];
  if (status == null) {
    return null;
  }
  return StatusPageStatus(
      status: status['description'], indicator: status['indicator']);
}

Future<dynamic> _getStatusBody(String url, http.Client client) async {
  try {
    final http.Response response = await client.get(url);
    final String body = response?.body;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  } catch (error) {
    print('Error fetching StatusPage status: $error');
    return null;
  }
}
