// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dashboard/widgets/lattice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LatticeScrollView pointer scrolling', () {
    late ScrollController horizontalController;
    late ScrollController verticalController;
    late List<List<LatticeCell>> cells;

    setUp(() {
      horizontalController = ScrollController();
      verticalController = ScrollController();
      cells = List<List<LatticeCell>>.generate(
        50,
        (row) => List<LatticeCell>.generate(
          50,
          (col) => LatticeCell(
            builder: (context) =>
                SizedBox(width: 50, height: 50, child: Text('R$row C$col')),
          ),
        ),
      );
    });

    tearDown(() {
      horizontalController.dispose();
      verticalController.dispose();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: LatticeScrollView(
              horizontalController: horizontalController,
              verticalController: verticalController,
              cells: cells,
            ),
          ),
        ),
      );
    }

    testWidgets('scrolls vertically when Shift key is not pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(LatticeScrollView));

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0.0, 50.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(verticalController.offset, 50.0);
      expect(horizontalController.offset, 0.0);
    });

    testWidgets('scrolls horizontally when Left Shift key is held', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(LatticeScrollView));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0.0, 100.0),
        ),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(verticalController.offset, 0.0);
      expect(horizontalController.offset, 100.0);
    });

    testWidgets('scrolls horizontally when Right Shift key is held', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(LatticeScrollView));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftRight);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0.0, 100.0),
        ),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftRight);
      await tester.pumpAndSettle();

      expect(verticalController.offset, 0.0);
      expect(horizontalController.offset, 100.0);
    });

    testWidgets('scrolls horizontally when scroll event has dx delta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(LatticeScrollView));

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(50.0, 0.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(verticalController.offset, 0.0);
      expect(horizontalController.offset, 50.0);
    });

    testWidgets('clamps horizontal scroll offset to min/max scroll extent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(LatticeScrollView));

      // Attempt to scroll left past minScrollExtent (0.0)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0.0, -100.0),
        ),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(horizontalController.offset, 0.0);

      // Scroll past maxScrollExtent
      final maxExtent = horizontalController.position.maxScrollExtent;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: Offset(0.0, maxExtent + 500.0),
        ),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(horizontalController.offset, maxExtent);
    });
  });
}
