// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Task;

import 'package:app_flutter/task_helper.dart';
import 'package:app_flutter/task_icon.dart';

void main() {
  group('TaskIcon', () {
    testWidgets('tooltip shows task name', (WidgetTester tester) async {
      const String taskName = 'tasky task';

      await tester.pumpWidget(
          MaterialApp(home: TaskIcon(task: Task()..name = taskName)));

      expect(find.text(taskName), findsNothing);

      final Finder taskIcon = find.byType(TaskIcon);
      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(taskIcon));
      await tester.pump(kLongPressTimeout);

      expect(find.text(taskName), findsOneWidget);

      await gesture.up();
    });

    testWidgets('tapping TaskIcon opens source configuration url',
        (WidgetTester tester) async {
      const MethodChannel urlLauncherChannel =
          MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      urlLauncherChannel.setMockMethodCallHandler(
          (MethodCall methodCall) async => log.add(methodCall));

      final Task devicelabTask = Task()
        ..stageName = 'devicelab'
        ..name = 'test';

      await tester.pumpWidget(MaterialApp(
        home: TaskIcon(
          task: devicelabTask,
        ),
      ));

      // Tap to open the source configuration
      await tester.tap(find.byType(TaskIcon));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': sourceConfigurationUrl(devicelabTask),
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

    testWidgets('unknown stage name shows helper icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: TaskIcon(task: Task()..stageName = 'stage not to be named')));

      expect(find.byIcon(Icons.help), findsOneWidget);
    });
  });
}
