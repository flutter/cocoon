// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/fake_cocoon.dart';
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
      final MockCocoonService errorService = MockCocoonService();

      when(errorService.fetchCommitStatuses())
          .thenAnswer((_) => Future<List<CommitStatus>>.error(0));
      when(errorService.fetchTreeBuildStatus())
          .thenAnswer((_) => Future<bool>.value(false));

      final FlutterBuildState buildState =
          FlutterBuildState(cocoonService: errorService);

      buildState.startFetchingBuildStateUpdates();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FlutterBuildState>(
            builder: (_) => buildState,
            child: BuildDashboard(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text(BuildDashboard.errorCocoonBackend), findsOneWidget);

      buildState.dispose();
    });
  });
}

/// [FakeCocoonService] for giving errors.
class MockCocoonService extends Mock implements FakeCocoonService {}
