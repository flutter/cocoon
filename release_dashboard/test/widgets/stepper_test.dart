// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../src/services/fake_conductor.dart';

void main() {
  testWidgets('When user clicks on a previously completed step, Stepper does not navigate back.',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor()),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[
                MainProgression(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(0));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Initialize a New Flutter Release'));
    await tester.pumpAndSettle();

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(1));
  });
}
