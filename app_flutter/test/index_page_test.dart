// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/index_page.dart';
import 'package:app_flutter/widgets/sign_in_button.dart';

import 'utils/wrapper.dart';

T getDescendant<T extends Widget>({@required Element of}) {
  return find
      .descendant(
        of: find.byElementPredicate((Element element) => element == of),
        matching: find.byType(T),
      )
      .evaluate()
      .single
      .widget as T;
}

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FakeInserter(child: IndexPage())));

    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('shows menu for navigation drawer', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FakeInserter(child: IndexPage())));

    expect(find.byIcon(Icons.menu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump(); // start animation of drawer opening
    await tester.pump(const Duration(seconds: 1)); // end animation of drawer opening

    final List<Element> raisedButtons = find.byType(TextButton).evaluate().toList();

    final List<Element> listTiles = find.byType(ListTile).evaluate().toList();

    expect(getDescendant<Text>(of: raisedButtons.last).data, 'SIGN IN');
    expect(getDescendant<Text>(of: listTiles.first).data, 'Home');
  });

  testWidgets('shows navigation buttons for dashboards', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FakeInserter(child: IndexPage())));

    expect(find.text('BUILD'), findsOneWidget);
    expect(find.text('FRAMEWORK BENCHMARKS ON SKIA PERF'), findsOneWidget);
    expect(find.text('ENGINE BENCHMARKS ON SKIA PERF'), findsOneWidget);
    expect(find.text('REPOSITORY'), findsOneWidget);
    expect(find.text('INFRA AGENTS'), findsOneWidget);
  });
}
