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
  const pb.ReleasePhase currentPhase = pb.ReleasePhase.PUBLISH_VERSION;
  const pb.ReleasePhase nextPhase = pb.ReleasePhase.PUBLISH_CHANNEL;
  group('framework PR is required', () {
    late pb.ConductorState stateWithFrameworkPR;

    setUp(() {
      stateWithFrameworkPR = generateConductorState(currentPhase: currentPhase);
    });

    group('UI tests', () {
      testWidgets('Titles and subtitles of checkboxes are rendered correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithFrameworkPR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.framework),
                  ],
                ),
              ),
            ),
          ),
        );

        for (final MergePrSubstep substep in MergePrSubstep.values) {
          // Update license hash and codesign substeps do not apply to the framework.
          if (substep == MergePrSubstep.updateLicenseHash || substep == MergePrSubstep.codesign) {
            expect(find.text(MergePrSubsteps.substepTitles[substep]!), findsNothing);
            expect(find.text(MergePrSubsteps.substepSubtitles[substep]!), findsNothing);
          } else {
            expect(find.text(MergePrSubsteps.substepTitles[substep]!), findsOneWidget);
            expect(find.text(MergePrSubsteps.substepSubtitles[substep]!), findsOneWidget);
          }
        }
      });

      testWidgets('Open a PR', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithFrameworkPR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.framework),
                  ],
                ),
              ),
            ),
          ),
        );

        final String newPrLink = getNewPrLink(
          userName: githubAccount(kFrameworkMirror),
          repoName: 'flutter',
          state: stateWithFrameworkPR,
        );

        expect(find.text(newPrLink), findsOneWidget);
        expect(find.byType(UrlButton), findsNWidgets(2));
      });

      group('Validate post-submit CI', () {
        for (final String releaseChannel in kBaseReleaseChannels) {
          testWidgets('Displays the correct $releaseChannel LUCI dashboard URL', (WidgetTester tester) async {
            stateWithFrameworkPR.releaseChannel = releaseChannel;
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (context) => StatusState(conductor: FakeConductor(testState: stateWithFrameworkPR)),
                child: MaterialApp(
                  home: Material(
                    child: ListView(
                      children: const [
                        MergePrSubsteps(repository: Repositories.framework),
                      ],
                    ),
                  ),
                ),
              ),
            );

            expect(find.text(luciConsoleLink(releaseChannel, 'flutter')), findsOneWidget);
          });
        }
      });

      testWidgets('Validate post-submit CI displays an error message if release channel is invalid',
          (WidgetTester tester) async {
        stateWithFrameworkPR.releaseChannel = 'master';
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithFrameworkPR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.framework),
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
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithFrameworkPR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.framework),
                  ],
                ),
              ),
            ),
          ),
        );

        final Finder continueButton = find.byKey(const Key('mergeFrameworkCherrypicksSubstepsContinue'));
        expect(continueButton, findsOneWidget);
        expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(false));

        for (final MergePrSubstep substep in MergePrSubstep.values) {
          if (substep != MergePrSubstep.updateLicenseHash && substep != MergePrSubstep.codesign) {
            await tester.tap(find.text(MergePrSubsteps.substepTitles[substep]!));
          }
        }
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0.0, -500.0));
        await tester.pump();
        expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(true));
      });
    });
  });

  group('Framework PR is not required', () {
    late pb.ConductorState stateWithoutFrameworkPR;

    setUp(() {
      stateWithoutFrameworkPR = generateConductorState(currentPhase: currentPhase, isFrameworkPrRequired: false);
    });

    testWidgets('No substep should be rendered', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutFrameworkPR)),
          child: MaterialApp(
            home: Material(
              child: ListView(
                children: const [
                  MergePrSubsteps(repository: Repositories.framework),
                ],
              ),
            ),
          ),
        ),
      );

      for (final MergePrSubstep substep in MergePrSubstep.values) {
        expect(find.text(MergePrSubsteps.substepTitles[substep]!), findsNothing);
        expect(find.text(MergePrSubsteps.substepSubtitles[substep]!), findsNothing);
      }
      expect(find.text(MergePrSubsteps.noPrMsg), findsOneWidget);
    });

    group('Checksteps and continue button logic tests', () {
      testWidgets('Continue button is enabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutFrameworkPR)),
            child: MaterialApp(
              home: Material(
                child: ListView(
                  children: const [
                    MergePrSubsteps(repository: Repositories.framework),
                  ],
                ),
              ),
            ),
          ),
        );

        final Finder continueButton = find.byKey(const Key('mergeFrameworkCherrypicksSubstepsContinue'));
        expect(continueButton, findsOneWidget);
        expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(true));
      });
    });
  });

  group('NextContext tests', () {
    late pb.ConductorState stateWithoutFrameworkPR;

    setUp(() {
      stateWithoutFrameworkPR = generateConductorState(currentPhase: currentPhase, isFrameworkPrRequired: false);
    });

    testWidgets('Clicking on the continue button proceeds to the next phase of the release',
        (WidgetTester tester) async {
      final pb.ConductorState nextPhaseState = generateConductorState(currentPhase: nextPhase);

      FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutFrameworkPR,
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
                  MergePrSubsteps(repository: Repositories.framework),
                ],
              ),
            ),
          ),
        ),
      );

      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      await tester.tap(find.byKey(const Key('mergeFrameworkCherrypicksSubstepsContinue')));
      await tester.pumpAndSettle();
      expect(fakeConductor.state?.currentPhase, equals(nextPhase));
    });

    testWidgets('Catch an exception correctly', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a general Exception';

      // Initialize a [FakeNextContext] that throws an error and attach it to the conductor.
      // That simulates the scenario when 'fakeNextContext.run()` is called, an error is thrown.
      final FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutFrameworkPR,
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
                  MergePrSubsteps(repository: Repositories.framework),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('mergeFrameworkCherrypicksSubstepsContinue')));
      await tester.pumpAndSettle();
      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });
  });
}
