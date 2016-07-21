// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:firebase_rest/firebase_rest.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

const firebaseBaseUrl = 'https://purple-butterfly-3000.firebaseio.com';

Firebase _measurements() {
  String firebaseToken = config.firebaseFlutterDashboardToken;
  return new Firebase(Uri.parse("$firebaseBaseUrl/measurements"),
      auth: firebaseToken);
}

Future<Null> uploadToFirebase(File measurementJson) async {
  if (!measurementJson.path.endsWith('.json'))
    fail("Error: path must be to a JSON file ending in .json");

  if (!exists(measurementJson))
    fail("Error: $measurementJson not found");

  String measurementKey = path.basenameWithoutExtension(measurementJson.path);
  print('Uploading $measurementJson to key $measurementKey');

  Firebase ref = _measurements();

  await ref
      .child(measurementKey)
      .child('current')
      .set(JSON.decode(measurementJson.readAsStringSync()));

  await ref
      .child(measurementKey)
      .child('history')
      .push(JSON.decode(measurementJson.readAsStringSync()));
}

Future<Null> uploadMeasurementToFirebase(String measurementKey, dynamic jsonData) async {
  Firebase ref = _measurements().child(measurementKey);
  print('Uploading ${ref.key}:\n${jsonData}');
  await ref.child('current').set(jsonData);
  await ref.child('history').push(jsonData);
}

Future<dynamic> firebaseDownloadCurrent(String measurementKey) async {
  DataSnapshot snapshot = await _measurements()
      .child(measurementKey)
      .child('current')
      .get();

  if (!snapshot.exists)
    return null;

  return snapshot.val;
}
