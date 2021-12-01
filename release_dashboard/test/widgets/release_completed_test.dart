// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/release_completed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
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
                return const ReleaseCompleted();
              }),
            ],
          ),
        ),
      ),
    ));

    expect(find.textContaining('Congratulations!'), findsOneWidget);
    expect(find.textContaining('has been successfully released'), findsOneWidget);
    expect(find.textContaining(kReleaseChannel), findsOneWidget);
    expect(find.textContaining(kReleaseVersion), findsOneWidget);
  });
}
