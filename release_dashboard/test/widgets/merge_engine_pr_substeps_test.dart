// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/models/repositories.dart';
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:conductor_ui/widgets/merge_pr_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('Engine PR is required', () {
    late pb.ConductorState stateWithEnginePR;

    setUp(() {
      stateWithEnginePR = generateConductorState();
    });

    group('UI tests', () {
      testWidgets('Titles and subtitles of checkboxes are rendered correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: [
                    MergePrSubsteps(nextStep: () {}, repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        for (final MergePrSubstep substep in MergePrSubstep.values) {
          expect(find.text(MergePrSubsteps.substepTitles[substep]!), findsOneWidget);
          expect(find.text(MergePrSubsteps.substepSubtitles[substep]!), findsOneWidget);
        }
      });

      testWidgets('Open a PR', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: [
                    MergePrSubsteps(nextStep: () {}, repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        final String newPrLink = getNewPrLink(
          userName: githubAccount(kEngineMirror),
          repoName: 'engine',
          state: stateWithEnginePR,
        );

        expect(find.text(newPrLink), findsOneWidget);
        expect(find.byType(UrlButton), findsNWidgets(2));
      });

      group('Validate post-submit CI', () {
        for (final String releaseChannel in kBaseReleaseChannels) {
          testWidgets('Displays the correct $releaseChannel LUCI dashboard URL', (WidgetTester tester) async {
            stateWithEnginePR.releaseChannel = releaseChannel;
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
                child: MaterialApp(
                  home: Material(
                    child: ListView(
                      children: [
                        MergePrSubsteps(nextStep: () {}, repository: Repositories.engine),
                      ],
                    ),
                  ),
                ),
              ),
            );

            expect(find.text(luciConsoleLink(releaseChannel, 'engine')), findsOneWidget);
          });
        }
      });

      testWidgets('Validate post-submit CI displays an error message if release channel is invalid',
          (WidgetTester tester) async {
        stateWithEnginePR.releaseChannel = 'master';
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: [
                    MergePrSubsteps(nextStep: () {}, repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text(MergePrSubsteps.releaseChannelInvalidErr), findsOneWidget);
      });
    });

    group('Checksteps and continue button logic tests', () {
      testWidgets('Continue button appears when all substeps are checked', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: [
                    MergePrSubsteps(nextStep: () {}, repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        final Finder continueButton = find.byKey(const Key('mergeEngineCherrypicksSubstepsContinue'));
        expect(continueButton, findsNothing);

        for (final MergePrSubstep substep in MergePrSubstep.values) {
          await tester.tap(find.text(MergePrSubsteps.substepTitles[substep]!));
        }
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0.0, -500.0));
        await tester.pump();
        expect(continueButton, findsOneWidget);
      });

      testWidgets('Click on the continue button proceeds to the next step', (WidgetTester tester) async {
        bool isNextStep = false;
        void nextStep() => isNextStep = true;

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: [
                    MergePrSubsteps(nextStep: nextStep, repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        for (final MergePrSubstep substep in MergePrSubstep.values) {
          await tester.tap(find.text(MergePrSubsteps.substepTitles[substep]!));
        }
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0.0, -500.0));
        await tester.pump();
        await tester.tap(find.byKey(const Key('mergeEngineCherrypicksSubstepsContinue')));
        await tester.pumpAndSettle();
        expect(isNextStep, equals(true));
      });
    });
  });
  group('Engine PR is not required', () {
    late pb.ConductorState stateWithoutEnginePR;

    setUp(() {
      stateWithoutEnginePR = generateConductorState(isEnginePrRequired: false);
    });

    testWidgets('Only renders the codesign substep', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutEnginePR)),
          child: MaterialApp(
            home: Material(
              child: ListView(
                children: [
                  MergePrSubsteps(nextStep: () {}, repository: Repositories.engine),
                ],
              ),
            ),
          ),
        ),
      );

      for (final MergePrSubstep substep in MergePrSubstep.values) {
        // Only expect the codesign substep when an engine PR is not required.
        if (substep == MergePrSubstep.codesign) {
          expect(find.text(MergePrSubsteps.substepTitles[substep]!), findsOneWidget);
          expect(find.text(MergePrSubsteps.substepSubtitles[substep]!), findsOneWidget);
        } else {
          expect(find.text(MergePrSubsteps.substepTitles[substep]!), findsNothing);
          expect(find.text(MergePrSubsteps.substepSubtitles[substep]!), findsNothing);
        }
      }
      expect(find.text(MergePrSubsteps.noPrMsg), findsOneWidget);
    });

    group('Checksteps and continue button logic tests', () {
      testWidgets('Continue button appears when the codesign step is checked', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: [
                    MergePrSubsteps(nextStep: () {}, repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        final Finder continueButton = find.byKey(const Key('mergeEngineCherrypicksSubstepsContinue'));
        expect(continueButton, findsNothing);

        await tester.tap(find.text(MergePrSubsteps.substepTitles[MergePrSubstep.codesign]!));
        await tester.pumpAndSettle();
        expect(continueButton, findsOneWidget);
      });

      testWidgets('Click on the continue button proceeds to the next step', (WidgetTester tester) async {
        bool isNextStep = false;
        void nextStep() => isNextStep = true;

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: [
                    MergePrSubsteps(nextStep: nextStep, repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        final Finder continueButton = find.byKey(const Key('mergeEngineCherrypicksSubstepsContinue'));
        await tester.tap(find.text(MergePrSubsteps.substepTitles[MergePrSubstep.codesign]!));
        await tester.pumpAndSettle();
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
        expect(isNextStep, equals(true));
      });
    });
  });
}
