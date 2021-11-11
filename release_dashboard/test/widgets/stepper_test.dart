// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/services/fake_conductor.dart';

void main() {
  testWidgets('When user clicks on a previously completed step, Stepper does not navigate back.',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          return Column(
            children: <Widget>[
              MainProgression(
                previousCompletedStep: 1,
                conductor: FakeConductor(),
              ),
            ],
          );
        }),
      ),
    );

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(1));

    await tester.tap(find.text('Initialize a New Flutter Release'));
    await tester.pumpAndSettle();

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(1));
  });
}
