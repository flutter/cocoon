// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/roll_sheriff.dart';

/// Look up Flutter engine auto-roller rotation sheriff
/// See https://docs.google.com/document/d/1n4wkZSFSciGnq_tKHGaaVxp1Jamav2Wgmt6v_IOAoVI.
/// This uses the "legacy" roller rotation API endpoints. "New" API endpoints not yet available.
/// See go/rotations-ng
Future<RollSheriff> fetchSheriff({http.Client client}) async {
  client ??= http.Client();
  final Map<String, dynamic> rotation = await _getStatusBody(client);
  if (rotation == null) {
    return null;
  }

  return RollSheriff(currentSheriff: rotation['emails'].first);
}

Future<dynamic> _getStatusBody(http.Client client) async {
  try {
    final http.Response response = await client.get('https://rota-ng.appspot.com/legacy/sheriff_flutter_engine.json');
    final String body = response?.body;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  } catch (error) {
    print('Error fetching roll sheriff: $error');
    return null;
  }
}
