// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/service/firebase_analytics.dart';
import 'package:flutter_dashboard/service/firebase_auth.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateMocks(<Type>[
  Client,
  CocoonService,
  BuildState,
  FirebaseAnalyticsService,
  FirebaseAnalytics,
  FirebaseAuthService,
  FirebaseAuth,
  UserCredential,
])
void main() {}
