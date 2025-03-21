// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Key;
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/widgets/luci_task_attempt_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../utils/fake_url_launcher.dart';

void main() {
  group('LuciTaskAttemptSummary', () {
    testWidgets(
      'shows nothing for 0 attempts - when buildNumberList is empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: <Widget>[
                LuciTaskAttemptSummary(task: Task()..buildNumberList = ''),
              ],
            ),
          ),
        );

        expect(find.byType(ElevatedButton), findsNothing);
      },
    );

    testWidgets('shows only 1 button for 1 attempt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(task: Task()..buildNumberList = '123'),
            ],
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNWidgets(1));
      expect(find.text('OPEN LOG FOR BUILD #123'), findsOneWidget);
    });

    testWidgets('shows multiple buttons for multiple attempts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(task: Task()..buildNumberList = '123,456'),
            ],
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNWidgets(2));
      expect(find.text('OPEN LOG FOR BUILD #123'), findsOneWidget);
      expect(find.text('OPEN LOG FOR BUILD #456'), findsOneWidget);
    });

    testWidgets('opens expected luci log url', (WidgetTester tester) async {
      final urlLauncher = FakeUrlLauncher();
      UrlLauncherPlatform.instance = urlLauncher;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(
                task:
                    Task()
                      ..buildNumberList = '123'
                      ..builderName = 'Linux',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(urlLauncher.launches, isNotEmpty);
      expect(
        urlLauncher.launches.single,
        'https://ci.chromium.org/p/flutter/builders/prod/Linux/123',
      );
    });

    testWidgets(
      'opens expected luci log url for when there are multiple tasks',
      (WidgetTester tester) async {
        final urlLauncher = FakeUrlLauncher();
        UrlLauncherPlatform.instance = urlLauncher;

        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: <Widget>[
                LuciTaskAttemptSummary(
                  task:
                      Task()
                        ..buildNumberList = '123,456'
                        ..builderName = 'Linux',
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.text('OPEN LOG FOR BUILD #456'));
        await tester.pump();

        expect(urlLauncher.launches, isNotEmpty);
        expect(
          urlLauncher.launches.single,
          '${LuciTaskAttemptSummary.luciProdLogBase}/prod/Linux/456',
        );
      },
    );

    testWidgets('opens expected dart-internal log url', (
      WidgetTester tester,
    ) async {
      final urlLauncher = FakeUrlLauncher();
      UrlLauncherPlatform.instance = urlLauncher;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(
                task:
                    Task()
                      ..buildNumberList = '123'
                      ..builderName = 'Linux flutter_release_builder',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(urlLauncher.launches, isNotEmpty);
      expect(
        urlLauncher.launches.single,
        '${LuciTaskAttemptSummary.dartInternalLogBase}/flutter/Linux/123',
      );
    });
  });
}
