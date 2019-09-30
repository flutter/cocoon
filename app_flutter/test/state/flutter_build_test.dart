// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/state/flutter_build.dart';

void main() {
  group('FlutterBuildState', () {
    test('multiple start updates should throw no exception', () {
      FlutterBuildState buildState = FlutterBuildState();

      buildState.startFetchingBuildStateUpdates();
      Timer refreshTimer = buildState.refreshTimer;

      // This second run should not change the refresh timer
      buildState.startFetchingBuildStateUpdates();

      expect(refreshTimer, equals(buildState.refreshTimer));
    });
  });
}
