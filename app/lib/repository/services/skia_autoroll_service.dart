// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/skia_autoroll.dart';

/// See https://autoroll.skia.org/r/flutter-engine-flutter-autoroll
///     https://autoroll.skia.org/r/skia-flutter-autoroll
Future<SkiaAutoRoll> fetchSkiaAutoRollModeStatus(String url,
    {http.Client client}) async {
  client ??= http.Client();
  final Map<String, dynamic> fetchedStatus = await _getStatusBody(url, client);
  if (fetchedStatus == null) {
    return null;
  }
  final Map<String, dynamic> mode = fetchedStatus['mode'];
  if (mode == null) {
    return null;
  }
  final Map<String, dynamic> lastRoll = fetchedStatus['lastRoll'];
  if (lastRoll == null) {
    return null;
  }
  return SkiaAutoRoll(mode: mode['mode'], lastRollResult: lastRoll['result']);
}

Future<dynamic> _getStatusBody(String url, http.Client client) async {
  try {
    final http.Response response = await client.get(url);
    final String body = response?.body;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  } catch (error) {
    print('Error fetching autoroller status: $error');
    return null;
  }
}
