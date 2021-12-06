// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/logic/cherrypick_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cherrypick State extension tests', () {
    cherrypickStates.forEach(
      (pb.CherrypickState state, String stateValue) => {
        test('$state state is able to be converted to its corresponding string correctly', () {
          expect(state.string(), equals(stateValue));
        })
      },
    );
  });
}
