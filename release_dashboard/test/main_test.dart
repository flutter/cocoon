// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:conductor_ui/main.dart';
import 'package:conductor_ui/widgets/clean_release_button.dart';
import 'package:conductor_ui/widgets/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/services/fake_conductor.dart';

void main() {
  group('Main app UI', () {
    testWidgets('Scaffold Initialization', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor()));

      expect(find.textContaining('Flutter Desktop Conductor'), findsOneWidget);
      expect(find.textContaining('Desktop app for managing a release'), findsOneWidget);
      expect(find.text('Please follow each step and substep in order.'), findsOneWidget);
      expect(find.byType(CleanReleaseButton), findsOneWidget);
      expect(find.byType(MainProgression), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Force push if off'), findsOneWidget);
    });
  }, skip: Platform.isWindows); // This app does not support Windows [intended]

  group('Force toggle tests', () {
    testWidgets('force is off initially', (WidgetTester tester) async {
      final FakeConductor fakeConductor = FakeConductor();
      await tester.pumpWidget(MyApp(fakeConductor));

      expect(fakeConductor.force, equals(false));
      expect(find.text('Force push if off'), findsOneWidget);
    });

    testWidgets('Toggle force from true to false', (WidgetTester tester) async {
      final FakeConductor fakeConductor = FakeConductor();
      await tester.pumpWidget(MyApp(fakeConductor));

      final Finder forceSwitch = find.byKey(const Key('forceSwitch'));
      expect(forceSwitch, findsOneWidget);

      expect(fakeConductor.force, equals(false));
      await tester.tap(forceSwitch);
      await tester.pumpAndSettle();
      expect(fakeConductor.force, equals(true));
      expect(find.text('Force push if on'), findsOneWidget);
    });

    testWidgets('Toggle force from false to true', (WidgetTester tester) async {
      final FakeConductor fakeConductor = FakeConductor();
      await tester.pumpWidget(MyApp(fakeConductor));

      final Finder forceSwitch = find.byKey(const Key('forceSwitch'));

      await tester.tap(forceSwitch);
      await tester.pumpAndSettle();
      expect(fakeConductor.force, equals(true));

      await tester.tap(forceSwitch);
      await tester.pumpAndSettle();
      expect(fakeConductor.force, equals(false));
      expect(find.text('Force push if off'), findsOneWidget);
    });
  });
}
