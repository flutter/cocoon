// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/status_grid.dart';

void main() {
  // TODO(chillers): smoke screen test, remove when actual tests added
  testWidgets('StatusGrid smoke test', (WidgetTester tester) async {
    // SingleChildScrollView needs an ancestor that has directionality
    await tester.pumpWidget(MaterialApp(
      home: StatusGrid(),
    ));

    expect(find.text('404'), findsNothing);

    // CommitBox is expected to throw an exception when loading images
    tester.takeException();
  });
}
