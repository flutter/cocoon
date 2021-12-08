// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:conductor_ui/main.dart';
import 'package:conductor_ui/widgets/clean_release_button.dart';
import 'package:conductor_ui/widgets/progression.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/services/fake_conductor.dart';

void main() {
  group('Main app', () {
    testWidgets('Scaffold Initialization', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor()));

      expect(find.textContaining('Flutter Desktop Conductor'), findsOneWidget);
      expect(find.textContaining('Desktop app for managing a release'), findsOneWidget);
      expect(find.text('Please follow each step and substep in order.'), findsOneWidget);
      expect(find.byType(CleanReleaseButton), findsOneWidget);
      expect(find.byType(MainProgression), findsOneWidget);
    });
  }, skip: Platform.isWindows); // This app does not support Windows [intended]
}
