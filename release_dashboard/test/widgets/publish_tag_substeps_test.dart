// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/publish_channel_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../src/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('Publish to the channel', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState();
    });
    testWidgets('UI tests', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return PublishTagSubsteps(nextStep: () {});
                }),
              ],
            ),
          ),
        ),
      ));

      expect(
          find.textContaining('Release tag $kReleaseVersion is ready to be published to the $kReleaseChannel channel'),
          findsOneWidget);
      expect(find.text('Publish release tag'), findsOneWidget);
      expect(find.textContaining('Very Important'), findsOneWidget);
      expect(find.textContaining('Please verify if the tag and the channel are correct'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Clicks on publish release tag button logics', (WidgetTester tester) async {
      bool isNextStep = false;
      void nextStep() => isNextStep = true;

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return PublishTagSubsteps(nextStep: nextStep);
                }),
              ],
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Publish release tag'));
      expect(isNextStep, equals(true));
    });
  });
}
