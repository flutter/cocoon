// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/common/checkbox_substep.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:conductor_ui/widgets/push_release_substep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../src/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('UI tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState();
    });
    testWidgets('Render all elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return PushReleaseSubsteps(
                    nextStep: () {},
                  );
                }),
              ],
            ),
          ),
        ),
      ));

      for (PushReleaseSubstep substep in PushReleaseSubstep.values) {
        expect(find.textContaining(PushReleaseSubsteps.substepTitles[substep]!), findsOneWidget);
        expect(find.textContaining(PushReleaseSubsteps.substepSubtitles[substep]!), findsOneWidget);
      }
      expect(find.byType(CheckboxAsSubstep), findsNWidgets(2));
    });

    testWidgets('Renders the release channel', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return PushReleaseSubsteps(
                    nextStep: () {},
                  );
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.textContaining(kReleaseChannel), findsNWidgets(2));
    });

    testWidgets('Renders the Luci link', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return PushReleaseSubsteps(
                    nextStep: () {},
                  );
                }),
              ],
            ),
          ),
        ),
      ));

      final String postMonitorLuci = luciConsoleLink(
        kReleaseChannel,
        'packaging',
      );
      expect(find.byType(UrlButton), findsOneWidget);
      expect(find.text(postMonitorLuci), findsOneWidget);
    });
  });

  group('Logic tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState();
    });
    testWidgets('Checking all substeps make the continue button appears', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return PushReleaseSubsteps(
                    nextStep: () {},
                  );
                }),
              ],
            ),
          ),
        ),
      ));

      Finder continueButton = find.byKey(const Key('pushReleaseContinue'));
      expect(continueButton, findsNothing);
      for (PushReleaseSubstep substep in PushReleaseSubstep.values) {
        await tester.tap(find.textContaining(PushReleaseSubsteps.substepTitles[substep]!));
      }
      await tester.pumpAndSettle();
      expect(continueButton, findsOneWidget);
    });

    testWidgets('Clicking on the continue button proceeds to the next step', (WidgetTester tester) async {
      bool isNextStep = false;
      void nextStep() => isNextStep = true;

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return PushReleaseSubsteps(
                    nextStep: nextStep,
                  );
                }),
              ],
            ),
          ),
        ),
      ));

      Finder continueButton = find.byKey(const Key('pushReleaseContinue'));
      for (PushReleaseSubstep substep in PushReleaseSubstep.values) {
        await tester.tap(find.textContaining(PushReleaseSubsteps.substepTitles[substep]!));
      }
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      expect(isNextStep, equals(true));
    });
  });
}
