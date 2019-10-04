// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import 'package:app_flutter/build_dashboard.dart';
import 'package:app_flutter/state/flutter_build.dart';

void main() {
  group('BuildDashboard', () {
    testWidgets('should show error when FlutterBuildState has error',
        (WidgetTester tester) async {
      final MockFlutterBuildState buildState = MockFlutterBuildState();

      when(buildState.hasError).thenReturn(true);
      when(buildState.statuses).thenReturn(
          CocoonResponse<List<CommitStatus>>()..error = 'status error');
      when(buildState.isTreeBuilding)
          .thenReturn(CocoonResponse<bool>()..data = false);

      buildState.startFetchingBuildStateUpdates();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FlutterBuildState>(
            builder: (_) => buildState,
            child: BuildDashboard(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Cocoon Backend is having issues'), findsOneWidget);

      buildState.dispose();
    });
  });
}

/// [FlutterBuildState] for giving errors.
class MockFlutterBuildState extends Mock implements FlutterBuildState {}
