// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/canvaskit_widget.dart';

void main() {
  group('CanvasKitWidget', () {
    testWidgets('use canvaskit child when FLUTTER_WEB_USE_SKIA=true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CanvasKitWidget(
            useCanvasKit: true,
            canvaskit: Text('canvaskit'),
            other: Text('not canvaskit'),
          ),
        ),
      );

      expect(find.text('canvaskit'), findsOneWidget);
      expect(find.text('not canvaskit'), findsNothing);
    });
    testWidgets('use canvaskit child when FLUTTER_WEB_USE_SKIA=false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CanvasKitWidget(
            useCanvasKit: false,
            canvaskit: Text('canvaskit'),
            other: Text('not canvaskit'),
          ),
        ),
      );

      expect(find.text('canvaskit'), findsNothing);
      expect(find.text('not canvaskit'), findsOneWidget);
    });
  });
}
