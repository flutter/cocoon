// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/main.dart';
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/clean_release_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_clean_context.dart';
import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('Clean release button UI tests', () {
    testWidgets('AlertDialog Appears', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor()),
          child: const MaterialApp(
            home: Scaffold(
              body: CleanReleaseButton(),
            ),
          ),
        ),
      );

      expect(find.byType(CleanReleaseButton), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byType(CleanReleaseButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('cleanContext integration tests', () {
    late pb.ConductorState state;

    setUp(() {
      state = generateConductorState();
    });
    testWidgets('Able to catch a general exception', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a general Exception';
      final FakeCleanContext fakeContext = FakeCleanContext(
        runOverride: () async => throw Exception(exceptionMsg),
      );

      await tester.pumpWidget(MyApp(FakeConductor(testState: state, fakeCleanContextProvided: fakeContext)));

      await performClean(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });

    testWidgets('Able to catch a conductor exception', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a Conductor Exception';
      final FakeCleanContext fakeContext = FakeCleanContext(
        runOverride: () async => throw ConductorException(exceptionMsg),
      );

      await tester.pumpWidget(MyApp(FakeConductor(testState: state, fakeCleanContextProvided: fakeContext)));

      await performClean(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });

    testWidgets('Successfully cleans if there is no exception', (WidgetTester tester) async {
      bool releaseCleaned = false;
      final FakeCleanContext fakeContext = FakeCleanContext(
        runOverride: () async => releaseCleaned = true,
      );

      await tester.pumpWidget(MyApp(FakeConductor(testState: state, fakeCleanContextProvided: fakeContext)));

      await performClean(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(releaseCleaned, equals(true));
    });
  });
}

Future<void> performClean(WidgetTester tester) async {
  await tester.tap(find.byType(CleanReleaseButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), CleanReleaseButton.requiredConfirmationString);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Yes'));
  await tester.pumpAndSettle();
}
