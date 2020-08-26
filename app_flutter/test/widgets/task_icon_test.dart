// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/logic/qualified_task.dart';
import 'package:app_flutter/widgets/task_icon.dart';

void main() {
  testWidgets('TaskIcon tooltip shows task name', (WidgetTester tester) async {
    const String stageName = 'stagey stage';
    const String taskName = 'tasky task';
    const String expectedLabel = 'tasky task (stagey stage)';

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(stageName, taskName, 'abc'),
          ),
        ),
      ),
    );

    expect(find.text(expectedLabel), findsNothing);

    final Finder taskIcon = find.byType(TaskIcon);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(taskIcon));
    await tester.pump(kLongPressTimeout);

    expect(find.text(expectedLabel), findsOneWidget);

    await gesture.up();
  });

  testWidgets('Tapping TaskIcon opens source configuration url', (WidgetTester tester) async {
    const MethodChannel urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
    final List<MethodCall> log = <MethodCall>[];
    urlLauncherChannel.setMockMethodCallHandler((MethodCall methodCall) async => log.add(methodCall));

    const QualifiedTask devicelabTask = QualifiedTask('devicelab', 'test', null);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: devicelabTask,
          ),
        ),
      ),
    );

    // Tap to open the source configuration
    await tester.tap(find.byType(TaskIcon));
    await tester.pump();

    expect(
      log,
      <Matcher>[
        isMethodCall('launch', arguments: <String, Object>{
          'url': devicelabTask.sourceConfigurationUrl,
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

  testWidgets('Unknown stage name shows helper icon in TaskIcon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask('stage not to be named', 'macbeth', null),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.help), findsOneWidget);
  });

  testWidgets('TaskIcon shows the right icon for cirrus', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask('cirrus', 'task', null),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image, isInstanceOf<AssetImage>());
    expect(((tester.widget(find.byType(Image)) as Image).image as AssetImage).assetName, 'assets/cirrus.png');
  });

  testWidgets('TaskIcon shows the right icon for devicelab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask('devicelab', 'task', null),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image, isInstanceOf<AssetImage>());
    expect(((tester.widget(find.byType(Image)) as Image).image as AssetImage).assetName, 'assets/android.png');
  });

  testWidgets('TaskIcon shows the right icon for devicelab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask('devicelab_win', 'task', null),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image, isInstanceOf<AssetImage>());
    expect(((tester.widget(find.byType(Image)) as Image).image as AssetImage).assetName, 'assets/windows.png');
  });
}
