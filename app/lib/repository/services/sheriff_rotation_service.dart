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
  final Map<String, dynamic> fetchedRotations = await _getStatusBody(client);
  if (fetchedRotations == null) {
    return null;
  }

  // Index of "flutter_engine" indicates the index of "participants" to check per calendar day.
  final List<dynamic> rotations = fetchedRotations['rotations'];
  if (rotations == null) {
    return null;
  }
  int flutterIndex = rotations.indexOf('flutter_engine');
  if (flutterIndex == -1) {
    return null;
  }

  final List<dynamic> calendars = fetchedRotations['calendar'];
  for (Map<String, dynamic> calendar in calendars.reversed) {
    List<dynamic> participants = calendar['participants'];
    List<dynamic> flutterSheriff = participants[flutterIndex];
    if (flutterSheriff != null && flutterSheriff.isNotEmpty) {
      return RollSheriff(currentSheriff: flutterSheriff.first);
    }
  }

  return null;
}

Future<dynamic> _getStatusBody(http.Client client) async {
  try {
    final http.Response response = await client.get('https://rota-ng.appspot.com/legacy/all_rotations.js');
    final String body = response?.body;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  } catch (error) {
    print('Error fetching roll sheriff: $error');
    return null;
  }
}
