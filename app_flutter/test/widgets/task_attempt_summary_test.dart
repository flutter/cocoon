// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Key;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/models.dart' show Key, RootKey, Task;

import 'package:app_flutter/widgets/task_attempt_summary.dart';

void main() {
  group('TaskAttemptSummary', () {
    testWidgets('shows nothing for 0 attempts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              TaskAttemptSummary(
                task: Task()..attempts = 0,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows only 1 button for 1 attempt', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              TaskAttemptSummary(
                task: Task()..attempts = 1,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNWidgets(1));
      expect(find.text('OPEN LOG FOR ATTEMPT #1'), findsOneWidget);
    });

    testWidgets('shows multiple buttons for multiple attempts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              TaskAttemptSummary(
                task: Task()..attempts = 3,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNWidgets(3));
      expect(find.text('OPEN LOG FOR ATTEMPT #1'), findsOneWidget);
      expect(find.text('OPEN LOG FOR ATTEMPT #2'), findsOneWidget);
      expect(find.text('OPEN LOG FOR ATTEMPT #3'), findsOneWidget);
    });

    testWidgets('opens expected stackdriver url', (WidgetTester tester) async {
      const MethodChannel channel = MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              TaskAttemptSummary(
                task: Task()
                  ..key = (RootKey()..child = (Key()..name = 'loggylog'))
                  ..attempts = 1,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url':
                'https://console.cloud.google.com/logs/viewer?project=flutter-dashboard&resource=global&minLogLevel=0&expandAll=false&interval=NO_LIMIT&dateRangeUnbound=backwardInTime&logName=projects%2Fflutter-dashboard%2Flogs%2Floggylog_1',
            'useSafariVC': true,
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{}
          })
        ],
      );
    });

    testWidgets('opens expected stackdriver url for when there are multiple tasks', (WidgetTester tester) async {
      const MethodChannel channel = MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              TaskAttemptSummary(
                task: Task()
                  ..key = (RootKey()..child = (Key()..name = 'loggylog'))
                  ..attempts = 3,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('OPEN LOG FOR ATTEMPT #2'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': '${TaskAttemptSummary.stackdriverLogUrlBase}loggylog_2',
            'useSafariVC': true,
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{}
          })
        ],
      );
    });
  });
}
