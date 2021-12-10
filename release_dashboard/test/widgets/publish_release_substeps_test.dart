// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/publish_release_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_next_context.dart';
import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  const pb.ReleasePhase currentPhase = pb.ReleasePhase.PUBLISH_CHANNEL;
  const pb.ReleasePhase nextPhase = pb.ReleasePhase.VERIFY_RELEASE;
  group('Publish to the channel UI tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: currentPhase);
    });
    testWidgets('Renders elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[PublishReleaseSubsteps()],
            ),
          ),
        ),
      ));

      expect(find.text('Release $kReleaseVersion is ready to be pushed to the remote $kReleaseChannel repository.'),
          findsOneWidget);
      expect(find.byKey(const Key('publishReleaseContinue')), findsOneWidget);
      expect(find.textContaining('Very Important'), findsOneWidget);
      expect(find.textContaining('Please verify if the release number and the channel are correct'), findsOneWidget);
    });
  });

  group('nextContext tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: currentPhase);
    });

    testWidgets('Clicks on continue button proceeds to the next step', (WidgetTester tester) async {
      final pb.ConductorState nextPhaseState = generateConductorState(currentPhase: nextPhase);

      FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutConflicts,
      );
      // Initialize a [FakeNextContext] that changes the state of the conductor to be at the
      // next phase, and attach it to the conductor. That simulates the scenario when
      // 'fakeNextContext.run()` is called, proceeds to the next phase of the release.
      FakeNextContext fakeNextContext = FakeNextContext(
        runOverride: () async => fakeConductor.testState = nextPhaseState,
      );
      fakeConductor.fakeNextContextProvided = fakeNextContext;

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[PublishReleaseSubsteps()],
            ),
          ),
        ),
      ));

      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      await tester.tap(find.byKey(const Key('publishReleaseContinue')));
      await tester.pumpAndSettle();
      expect(fakeConductor.state?.currentPhase, equals(nextPhase));
    });

    testWidgets('Catch an exception correctly', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a general Exception';

      // Initialize a [FakeNextContext] that throws an error and attach it to the conductor.
      // That simulates the scenario when 'fakeNextContext.run()` is called, an error is thrown.
      final FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutConflicts,
        fakeNextContextProvided: FakeNextContext(
          runOverride: () async => throw Exception(exceptionMsg),
        ),
      );

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: ListView(
              children: const <Widget>[PublishReleaseSubsteps()],
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('publishReleaseContinue')));
      await tester.pumpAndSettle();
      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });
  });
}
