// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/index_page.dart';
import 'package:app_flutter/sign_in_button.dart';

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
    await tester.pumpWidget(MaterialApp(home: IndexPage()));

    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('shows menu for navigation drawer', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: IndexPage()));

    expect(find.byIcon(Icons.menu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump(); // start animation of drawer opening
    await tester.pump(const Duration(seconds: 1)); // end animation of drawer opening

    final List<Element> raisedButtons = find.byType(RawMaterialButton).evaluate().toList();

    final List<Element> listTiles = find.byType(ListTile).evaluate().toList();

    expect(raisedButtons, hasLength(6));
    expect(listTiles.length, greaterThanOrEqualTo(raisedButtons.length + 1));

    expect(getDescendant<Text>(of: raisedButtons.last).data, 'SIGN IN');
    expect(getDescendant<Text>(of: listTiles.first).data, 'Home');

    for (int index = 0; index < raisedButtons.length - 1; index += 1) {
      expect(getDescendant<Icon>(of: raisedButtons[index]).icon, getDescendant<Icon>(of: listTiles[index + 1]).icon);
      expect(getDescendant<Text>(of: raisedButtons[index]).data,
          getDescendant<Text>(of: listTiles[index + 1]).data.toUpperCase());
    }
  });

  testWidgets('shows navigation buttons for dashboards', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: IndexPage()));

    expect(find.text('BUILD'), findsOneWidget);
    expect(find.text('BENCHMARKS'), findsOneWidget);
    expect(find.text('BENCHMARKS ON SKIA PERF'), findsOneWidget);
    expect(find.text('REPOSITORY'), findsOneWidget);
    expect(find.text('INFRA AGENTS'), findsOneWidget);
  });
}
