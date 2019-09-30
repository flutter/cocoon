// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/state/flutter_build.dart';

void main() {
  group('FlutterBuildState', () {
    test('multiple start updates throws exception', () {
      FlutterBuildState buildState = FlutterBuildState();

      buildState.startFetchingBuildStateUpdates();

      expect(() => buildState.startFetchingBuildStateUpdates(),
          throwsA(equals('already fetching build state updates')));
    });
  });
}
