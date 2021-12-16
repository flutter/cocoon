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

import '../fakes/fake_next_context.dart';
import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  const pb.ReleasePhase currentPhase = pb.ReleasePhase.CODESIGN_ENGINE_BINARIES;
  const pb.ReleasePhase nextPhase = pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS;
  group('Engine PR is required', () {
    late pb.ConductorState stateWithEnginePR;

    setUp(() {
      stateWithEnginePR = generateConductorState(currentPhase: currentPhase);
    });

    group('UI tests', () {
      testWidgets('Titles and subtitles of checkboxes are rendered correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.engine),
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
                  children: const [
                    MergePrSubsteps(repository: Repositories.engine),
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
                      children: const [
                        MergePrSubsteps(repository: Repositories.engine),
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
                  children: const [
                    MergePrSubsteps(repository: Repositories.engine),
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
      testWidgets('Continue button enables when all substeps are checked', (WidgetTester tester) async {
        // Make sure the screen is large enough for the widgets to be found.
        tester.binding.window.physicalSizeTestValue = const Size(2000, 4000);

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        final Finder continueButton = find.byKey(const Key('mergeEngineCherrypicksSubstepsContinue'));
        expect(continueButton, findsOneWidget);
        expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(false));

        for (final MergePrSubstep substep in MergePrSubstep.values) {
          await tester.tap(find.text(MergePrSubsteps.substepTitles[substep]!));
        }
        await tester.pumpAndSettle();
        expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(true));
      });
    });
  });

  group('Engine PR is not required', () {
    late pb.ConductorState stateWithoutEnginePR;

    setUp(() {
      stateWithoutEnginePR = generateConductorState(currentPhase: currentPhase, isEnginePrRequired: false);
    });

    testWidgets('Only renders the codesign substep', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutEnginePR)),
          child: MaterialApp(
            home: Material(
              child: ListView(
                children: const [
                  MergePrSubsteps(repository: Repositories.engine),
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
      testWidgets('Continue button enables when the codesign step is checked', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutEnginePR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.engine),
                  ],
                ),
              ),
            ),
          ),
        );

        final Finder continueButton = find.byKey(const Key('mergeEngineCherrypicksSubstepsContinue'));
        expect(continueButton, findsOneWidget);
        expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(false));

        await tester.tap(find.text(MergePrSubsteps.substepTitles[MergePrSubstep.codesign]!));
        await tester.pumpAndSettle();
        expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(true));
      });
    });
  });

  group('NextContext tests', () {
    late pb.ConductorState stateWithoutEnginePR;

    setUp(() {
      stateWithoutEnginePR = generateConductorState(currentPhase: currentPhase, isEnginePrRequired: false);
    });

    testWidgets('Clicking on the continue button proceeds to the next phase of the release',
        (WidgetTester tester) async {
      final pb.ConductorState nextPhaseState = generateConductorState(currentPhase: nextPhase);

      FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutEnginePR,
      );
      // Initialize a [FakeNextContext] that changes the state of the conductor to be at the
      // next phase, and attach it to the conductor. That simulates the scenario when
      // 'fakeNextContext.run()` is called, proceeds to the next phase of the release.
      FakeNextContext fakeNextContext = FakeNextContext(
        runOverride: () async => fakeConductor.testState = nextPhaseState,
      );
      fakeConductor.fakeNextContextProvided = fakeNextContext;

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: fakeConductor),
          child: MaterialApp(
            home: Material(
              child: ListView(
                children: const [
                  MergePrSubsteps(repository: Repositories.engine),
                ],
              ),
            ),
          ),
        ),
      );

      final Finder continueButton = find.byKey(const Key('mergeEngineCherrypicksSubstepsContinue'));
      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      await tester.tap(find.text(MergePrSubsteps.substepTitles[MergePrSubstep.codesign]!));
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(fakeConductor.state?.currentPhase, equals(nextPhase));
    });

    testWidgets('Catch an exception correctly', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a general Exception';

      // Initialize a [FakeNextContext] that throws an error and attach it to the conductor.
      // That simulates the scenario when 'fakeNextContext.run()` is called, an error is thrown.
      final FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutEnginePR,
        fakeNextContextProvided: FakeNextContext(
          runOverride: () async => throw Exception(exceptionMsg),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: fakeConductor),
          child: MaterialApp(
            home: Material(
              child: ListView(
                children: const [
                  MergePrSubsteps(repository: Repositories.engine),
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
      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });
  });
}
