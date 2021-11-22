// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/codesign_engine_substeps.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../src/services/fake_conductor.dart';

void main() {
  group('UI tests', () {
    testWidgets('Titles and subtitles of checkboxes are rendered correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor()),
          child: MaterialApp(
            home: Material(
              child: CodesignEngineSubsteps(nextStep: () {}),
            ),
          ),
        ),
      );

      for (final CodesignEngineSubstep substep in CodesignEngineSubstep.values) {
        expect(find.text(CodesignEngineSubsteps.substepTitles[substep]!), findsOneWidget);
        expect(find.text(CodesignEngineSubsteps.substepSubtitles[substep]!), findsOneWidget);
      }
    });

    group('Validate post-submit CI', () {
      for (final String releaseChannel in CreateReleaseSubsteps.releaseChannels) {
        testWidgets('Displays the correct $releaseChannel LUCI dashboard URL', (WidgetTester tester) async {
          final pb.ConductorState testState = pb.ConductorState(
            releaseChannel: releaseChannel,
          );
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (context) => StatusState(conductor: FakeConductor(testState: testState)),
              child: MaterialApp(
                home: Material(
                  child: CodesignEngineSubsteps(nextStep: () {}),
                ),
              ),
            ),
          );

          expect(find.text(luciConsoleLink(releaseChannel, 'engine')), findsOneWidget);
          expect(find.byType(UrlButton), findsOneWidget);
        });
      }
    });

    testWidgets('Validate post-submit CI displays an error message if state is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor()),
          child: MaterialApp(
            home: Material(
              child: CodesignEngineSubsteps(nextStep: () {}),
            ),
          ),
        ),
      );

      expect(find.text(CodesignEngineSubsteps.releaseChannelMissingErr), findsOneWidget);
      expect(find.byType(UrlButton), findsNothing);
    });
  });

  group('Checksteps and continue button logic tests', () {
    testWidgets('Continue button appears when all substeps are checked', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor()),
          child: MaterialApp(
            home: Material(
              child: CodesignEngineSubsteps(nextStep: () {}),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('CodesignEngineSubstepsContinue')), findsNothing);

      for (final CodesignEngineSubstep substep in CodesignEngineSubstep.values) {
        await tester.tap(find.text(CodesignEngineSubsteps.substepTitles[substep]!));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('CodesignEngineSubstepsContinue')), findsOneWidget);
    });

    testWidgets('Click on the continue button proceeds to the next step', (WidgetTester tester) async {
      bool isNextStep = false;
      void nextStep() => isNextStep = true;

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor()),
          child: MaterialApp(
            home: Material(
              child: CodesignEngineSubsteps(nextStep: nextStep),
            ),
          ),
        ),
      );

      for (final CodesignEngineSubstep substep in CodesignEngineSubstep.values) {
        await tester.tap(find.text(CodesignEngineSubsteps.substepTitles[substep]!));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('CodesignEngineSubstepsContinue')));
      await tester.pumpAndSettle();
      expect(isNextStep, equals(true));
    });
  });
}
