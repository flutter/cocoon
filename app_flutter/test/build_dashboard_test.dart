// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/build_dashboard.dart';
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/flutter_build.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final FlutterBuildState buildState = FlutterBuildState();

    await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<FlutterBuildState>(
      builder: (_) => buildState,
      child: BuildDashboard(),
    )));

    expect(find.byType(SignInButton), findsOneWidget);
  });
}
