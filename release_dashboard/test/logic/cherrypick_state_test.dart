// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/cherrypick_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cherrypick State extension tests', () {
    for (MapEntry cherrypickState in cherrypickStates.entries) {
      test('${cherrypickState.key} state is able to be converted to its corresponding string correctly', () {
        expect(cherrypickState.key.toString(), equals(cherrypickState.value));
      });
    }
  });
}
