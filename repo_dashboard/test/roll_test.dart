// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:repository_dashboard/details/roll.dart';
import 'package:repository_dashboard/models/skia_autoroll.dart';
import 'package:repository_dashboard/models/providers.dart';

void main() {
  group('roll widget', () {
    testWidgets('running', (WidgetTester tester) async {
      const String modeText = 'running';
      const String lastRollResult = 'roll result';
      const SkiaAutoRoll roll = SkiaAutoRoll(mode: modeText, lastRollResult: lastRollResult);
      await _pumpAutoRollWidget(tester, roll);

      final Finder modeFinder = find.text(modeText);
      expect(modeFinder, findsOneWidget);

      final Finder lastRollResultFinder = find.text(lastRollResult);
      expect(lastRollResultFinder, findsOneWidget);

      final Finder iconFinder = find.byIcon(Icons.check);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('stopped', (WidgetTester tester) async {
      const SkiaAutoRoll roll = SkiaAutoRoll(mode: 'dry run', lastRollResult: 'roll result');
      await _pumpAutoRollWidget(tester, roll);
      final Finder iconFinder = find.byIcon(Icons.warning);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('dry run', (WidgetTester tester) async {
      const SkiaAutoRoll roll = SkiaAutoRoll(mode: 'stopped', lastRollResult: 'roll result');
      await _pumpAutoRollWidget(tester, roll);
      final Finder iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Bogus', (WidgetTester tester) async {
      const SkiaAutoRoll roll = SkiaAutoRoll(mode: 'bogus unknown mode');
      await _pumpAutoRollWidget(tester, roll);
      final Finder iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Unknown', (WidgetTester tester) async {
      const SkiaAutoRoll roll = SkiaAutoRoll();
      await _pumpAutoRollWidget(tester, roll);

      final Finder iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);

      final Finder modeFinder = find.text('Unknown');
      expect(modeFinder, findsOneWidget);
    });
  });
}

Future<void> _pumpAutoRollWidget(WidgetTester tester, SkiaAutoRoll roll) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ModelBinding<SkiaAutoRoll>(
              initialModel: roll,
              child: const AutoRollWidget(
                name: 'Random Roller',
                url: 'https://store.google.com',
              )))));
}
