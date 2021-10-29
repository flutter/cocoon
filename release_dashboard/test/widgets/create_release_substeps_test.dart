// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String candidateBranch = 'flutter-1.2-candidate.3';
  const String releaseChannel = 'dev';
  const String frameworkMirror = 'git@github.com:test/flutter.git';
  const String engineMirror = 'git@github.com:test/engine.git';
  const String engineCherrypick = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0,94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
  const String frameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
  const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
  const String increment = 'y';
  testWidgets('Widget should save all parameters correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: ListView(
                children: <Widget>[
                  CreateReleaseSubsteps(
                    nextStep: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await tester.enterText(find.byKey(const Key('Candidate Branch')), candidateBranch);

    final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
    final CreateReleaseSubstepsState createReleaseSubstepsState =
        createReleaseSubsteps.state as CreateReleaseSubstepsState;

    /// Tests the Release Channel dropdown menu.
    await tester.tap(find.byKey(const Key('Release Channel')));
    await tester.pumpAndSettle(); // finish the menu animation
    expect(createReleaseSubstepsState.releaseData['Release Channel'], equals(null));
    await tester.tap(find.text(releaseChannel).last);
    await tester.pumpAndSettle(); // finish the menu animation

    await tester.enterText(find.byKey(const Key('Framework Mirror')), frameworkMirror);
    await tester.enterText(find.byKey(const Key('Engine Mirror')), engineMirror);
    await tester.enterText(find.byKey(const Key('Engine Cherrypicks (if necessary)')), engineCherrypick);
    await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')), frameworkCherrypick);
    await tester.enterText(find.byKey(const Key('Dart Revision (if necessary)')), dartRevision);

    /// Tests the Increment dropdown menu.
    await tester.tap(find.byKey(const Key('Increment')));
    await tester.pumpAndSettle(); // finish the menu animation
    expect(createReleaseSubstepsState.releaseData['Increment'], equals(null));
    await tester.tap(find.text(increment).last);
    await tester.pumpAndSettle(); // finish the menu animation

    expect(
        createReleaseSubstepsState.releaseData,
        equals(<String, String>{
          'Candidate Branch': candidateBranch,
          'Release Channel': releaseChannel,
          'Framework Mirror': frameworkMirror,
          'Engine Mirror': engineMirror,
          'Engine Cherrypicks (if necessary)': engineCherrypick,
          'Framework Cherrypicks (if necessary)': frameworkCherrypick,
          'Dart Revision (if necessary)': dartRevision,
          'Increment': increment,
        }));
  });

  testWidgets('Parameters validators should catch all bad formatting', (WidgetTester tester) async {
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: ListView(
                children: <Widget>[
                  CreateReleaseSubsteps(
                    nextStep: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final Finder continueButton = find.byKey(const Key('step1continue'));
    expect(tester.widget<ElevatedButton>(continueButton).enabled, false);
    final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
    final CreateReleaseSubstepsState createReleaseSubstepsState =
        createReleaseSubsteps.state as CreateReleaseSubstepsState;
    final List<bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;
    expect(isEachInputValid, equals(<bool>[false, false, false, false, true, true, true, false]));

    await tester.enterText(find.byKey(const Key('Candidate Branch')), candidateBranch);
    expect(isEachInputValid, equals(<bool>[true, false, false, false, true, true, true, false]));

    await tester.tap(find.byKey(const Key('Release Channel')));
    await tester.pumpAndSettle(); // finish the menu animation
    await tester.tap(find.text(releaseChannel).last);
    await tester.pumpAndSettle();
    expect(isEachInputValid, equals(<bool>[true, true, false, false, true, true, true, false]));

    await tester.enterText(find.byKey(const Key('Framework Mirror')), frameworkMirror);
    expect(isEachInputValid, equals(<bool>[true, true, true, false, true, true, true, false]));

    await tester.enterText(find.byKey(const Key('Engine Mirror')), engineMirror);
    expect(isEachInputValid, equals(<bool>[true, true, true, true, true, true, true, false]));

    await tester.tap(find.byKey(const Key('Increment')));
    await tester.pumpAndSettle(); // finish the menu animation
    await tester.tap(find.text(increment).last);
    await tester.pumpAndSettle();
    expect(isEachInputValid, equals(<bool>[true, true, true, true, true, true, true, true]));

    // the fields below are optional, the continue button should be enabled even they are empty
    expect(tester.widget<ElevatedButton>(continueButton).enabled, true);
    await tester.enterText(find.byKey(const Key('Engine Cherrypicks (if necessary)')), engineCherrypick);
    await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')), frameworkCherrypick);
    await tester.enterText(find.byKey(const Key('Dart Revision (if necessary)')), dartRevision);
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(continueButton).enabled, true);
    expect(isEachInputValid, equals(<bool>[true, true, true, true, true, true, true, true]));

    await tester.enterText(find.byKey(const Key('Engine Cherrypicks (if necessary)')), '@@#@@@');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(continueButton).enabled, false);
    expect(isEachInputValid, equals(<bool>[true, true, true, true, false, true, true, true]));

    await tester.enterText(find.byKey(const Key('Framework Mirror')), '@@#@@@');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(continueButton).enabled, false);
    expect(isEachInputValid, equals(<bool>[true, true, false, true, false, true, true, true]));
  });
}
