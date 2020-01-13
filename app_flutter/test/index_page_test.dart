// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/index_page.dart';
import 'package:app_flutter/sign_in_button.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: IndexPage()));

    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('shows menu for navigation drawer', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: IndexPage()));

    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('shows navigation buttons for dashboards',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: IndexPage()));

    expect(find.text('Build'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Repository'), findsOneWidget);
    expect(find.text('Infra Agents'), findsOneWidget);
  });
}
