// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/widgets/task_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../utils/fake_url_launcher.dart';

void main() {
  testWidgets('TaskIcon tooltip shows task name', (WidgetTester tester) async {
    const stageName = 'stagey stage';
    const taskName = 'tasky task';
    const expectedLabel = 'tasky task (stagey stage)';

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(stage: stageName, task: taskName),
          ),
        ),
      ),
    );

    expect(find.text(expectedLabel), findsNothing);

    final taskIcon = find.byType(TaskIcon);
    final gesture = await tester.startGesture(tester.getCenter(taskIcon));
    await tester.pump(kLongPressTimeout);

    expect(find.text(expectedLabel), findsOneWidget);

    await gesture.up();
  });

  testWidgets('Tapping TaskIcon opens source configuration url',
      (WidgetTester tester) async {
    final urlLauncher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = urlLauncher;

    const luciTask = QualifiedTask(stage: StageName.luci, task: 'test');

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: luciTask,
          ),
        ),
      ),
    );

    // Tap to open the source configuration
    await tester.tap(find.byType(TaskIcon));
    await tester.pump();

    expect(urlLauncher.launches, isNotEmpty);
    expect(urlLauncher.launches.single, luciTask.sourceConfigurationUrl);
  });

  testWidgets('Unknown stage name shows helper icon in TaskIcon',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask:
                QualifiedTask(stage: 'stage not to be named', task: 'macbeth'),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.help), findsOneWidget);
  });

  testWidgets('TaskIcon shows the right icon for google test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(stage: 'google_internal'),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image,
        isInstanceOf<AssetImage>());
    expect(
        ((tester.widget(find.byType(Image)) as Image).image as AssetImage)
            .assetName,
        'assets/googleLogo.png');
  });

  testWidgets('TaskIcon shows the right icon for web',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'chromebot',
                task: 'Windows_web test',
                pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image,
        isInstanceOf<AssetImage>());
    expect(
        ((tester.widget(find.byType(Image)) as Image).image as AssetImage)
            .assetName,
        'assets/chromium.png');
  });

  testWidgets('TaskIcon shows the right icon for LUCI windows',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'chromebot',
                task: 'Windows something',
                pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image,
        isInstanceOf<AssetImage>());
    expect(
        ((tester.widget(find.byType(Image)) as Image).image as AssetImage)
            .assetName,
        'assets/windows.png');
  });

  testWidgets('TaskIcon shows the right icon for fuchsia',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'chromebot',
                task: 'Windows_fuchsia something',
                pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image,
        isInstanceOf<AssetImage>());
    expect(
        ((tester.widget(find.byType(Image)) as Image).image as AssetImage)
            .assetName,
        'assets/fuchsia.png');
  });

  testWidgets('TaskIcon shows the right icon for LUCI android',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              TaskIcon(
                qualifiedTask: QualifiedTask(
                    stage: 'chromebot', task: 'Windows_android test'),
              ),
              TaskIcon(
                qualifiedTask: QualifiedTask(
                    stage: 'chromebot', task: 'Windows_pixel_7pro test'),
              ),
              TaskIcon(
                qualifiedTask: QualifiedTask(
                    stage: 'chromebot', task: 'Windows_mokey test'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.android), findsExactly(3));
  });

  testWidgets('TaskIcon shows the right icon for LUCI mac',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'chromebot',
                task: 'Mac test',
                pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image,
        isInstanceOf<AssetImage>());
    expect(
        ((tester.widget(find.byType(Image)) as Image).image as AssetImage)
            .assetName,
        'assets/apple.png');
  });

  testWidgets('TaskIcon shows the right icon for LUCI mac/iphone',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'chromebot',
                task: 'Mac_ios test',
                pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect(tester.widget(find.byType(Icon)) as Icon, isInstanceOf<Icon>());
    expect((tester.widget(find.byType(Icon)) as Icon).icon!.codePoint,
        const Icon(Icons.phone_iphone).icon!.codePoint);
  });

  testWidgets('TaskIcon shows the right icon for LUCI linux',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'chromebot',
                task: 'Linux test',
                pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image,
        isInstanceOf<AssetImage>());
    expect(
        ((tester.widget(find.byType(Image)) as Image).image as AssetImage)
            .assetName,
        'assets/linux.png');
  });

  testWidgets('TaskIcon shows the right icon for unknown',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'chromebot', task: 'Unknown', pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect(tester.widget(find.byType(Icon)) as Icon, isInstanceOf<Icon>());
    expect((tester.widget(find.byType(Icon)) as Icon).icon!.codePoint,
        const Icon(Icons.help).icon!.codePoint);
  });

  testWidgets('TaskIcon shows the right icon for dart-internal linux',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TaskIcon(
            qualifiedTask: QualifiedTask(
                stage: 'dart-internal',
                task: 'Linux dart-internal test',
                pool: 'luci.flutter.prod'),
          ),
        ),
      ),
    );

    expect((tester.widget(find.byType(Image)) as Image).image,
        isInstanceOf<AssetImage>());
    expect(
        ((tester.widget(find.byType(Image)) as Image).image as AssetImage)
            .assetName,
        'assets/linux.png');
  });
}
