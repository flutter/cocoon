// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/build_dashboard.dart';
import 'package:app_flutter/sign_in_button.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final BuildDashboardPage buildDashboard = BuildDashboardPage();
    await tester.pumpWidget(MaterialApp(
      home: buildDashboard,
    ));

    expect(find.byType(SignInButton), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 100));
  });
}
