// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_rest/firebase_rest.dart';

import 'utils.dart';

const firebaseBaseUrl = 'https://purple-butterfly-3000.firebaseio.com';

Firebase _measurements() {
  String firebaseToken = config.firebaseFlutterDashboardToken;
  return new Firebase(Uri.parse("$firebaseBaseUrl/measurements"),
      auth: firebaseToken);
}

Future<HealthCheckResult> checkFirebaseConnection() async {
  if ((await _measurements().child('dashboard_bot_status').child('current').get()).val == null) {
    return new HealthCheckResult.failure(
      'Connection to Firebase is unhealthy. Failed to read the current dashboard_bot_status entity.'
    );
  } else {
    return new HealthCheckResult.success();
  }
}

Future<Null> uploadToFirebase(String measurementKey, dynamic jsonData) async {
  Firebase ref = _measurements().child(measurementKey);
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
