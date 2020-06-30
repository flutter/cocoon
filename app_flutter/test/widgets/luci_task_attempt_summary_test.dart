// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Key;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Key, RootKey, Task;

import 'package:app_flutter/widgets/luci_task_attempt_summary.dart';

void main() {
  group('LuciTaskAttemptSummary', () {
    testWidgets('shows nothing for 0 attempts - when buildNumberList is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(
                task: Task()..buildNumberList = '',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(RaisedButton), findsNothing);
    });

    testWidgets('shows only 1 button for 1 attempt',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(
                task: Task()..buildNumberList = '123',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(RaisedButton), findsNWidgets(1));
      expect(find.text('OPEN LOG FOR BUILD #123'), findsOneWidget);
    });

    testWidgets('shows multiple buttons for multiple attempts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(
                task: Task()..buildNumberList = '123,456',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(RaisedButton), findsNWidgets(2));
      expect(find.text('OPEN LOG FOR BUILD #123'), findsOneWidget);
      expect(find.text('OPEN LOG FOR BUILD #456'), findsOneWidget);
    });

    testWidgets('opens expected luci log url', (WidgetTester tester) async {
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(
                task: Task()
                  ..key = (RootKey()..child = (Key()..name = 'loggylog'))
                  ..buildNumberList = '123'
                  ..builderName = 'Linux',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(RaisedButton));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'https://ci.chromium.org/p/flutter/builders/prod/Linux/123',
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

    testWidgets('opens expected luci log url for when there are multiple tasks',
        (WidgetTester tester) async {
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              LuciTaskAttemptSummary(
                task: Task()
                  ..key = (RootKey()..child = (Key()..name = 'loggylog'))
                  ..buildNumberList = '123,456'
                  ..builderName = 'Linux',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('OPEN LOG FOR BUILD #456'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': '${LuciTaskAttemptSummary.luciProdLogBase}Linux/456',
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
