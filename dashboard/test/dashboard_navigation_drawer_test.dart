// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_dashboard/main.dart';
import 'package:flutter_dashboard/dashboard_navigation_drawer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'utils/fake_url_launcher.dart';
import 'utils/wrapper.dart';

void main() {
  void configureView(TestFlutterView view) {
    view.devicePixelRatio = 1.0;
    view.physicalSize = const Size(1080, 2280);
    addTearDown(view.reset);
  }

  group('DashboardNavigationDrawer', () {
    late FakeUrlLauncher urlLauncher;

    setUp(() {
      urlLauncher = FakeUrlLauncher();
      UrlLauncherPlatform.instance = urlLauncher;
    });

    testWidgets('lists all pages', (WidgetTester tester) async {
      configureView(tester.view);
      await tester.pumpWidget(
        const MaterialApp(
          title: 'Test',
          home: DashboardNavigationDrawer(),
        ),
      );

      expect(find.text('Build'), findsOneWidget);
      expect(find.text('Framework Benchmarks'), findsOneWidget);
      expect(find.text('Engine Benchmarks'), findsOneWidget);
      expect(find.text('Source Code'), findsOneWidget);
      await tester.drag(find.text('Source Code'), const Offset(0.0, -100));
      await tester.pump();
      expect(find.text('About Test'), findsOneWidget);
    });

    testWidgets('build navigates to build Flutter route', (WidgetTester tester) async {
      configureView(tester.view);
      final MockNavigatorObserver navigatorObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: const DashboardNavigationDrawer(),
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/build': (BuildContext context) => const Text('i am build'),
          },
          navigatorObservers: <NavigatorObserver>[navigatorObserver],
        ),
      );

      verifyNever(navigatorObserver.didReplace());
      expect(find.text('i am build'), findsNothing);

      // Click the nav item for build
      await tester.tap(find.text('Build'));
      await tester.pumpAndSettle();

      verify(navigatorObserver.didReplace(newRoute: anyNamed('newRoute'), oldRoute: anyNamed('oldRoute'))).called(1);
      expect(find.text('i am build'), findsOneWidget);
    });

    testWidgets('skia perf links opens skia perf url', (WidgetTester tester) async {
      configureView(tester.view);
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardNavigationDrawer(),
        ),
      );

      const String skiaPerfText = 'Engine Benchmarks';
      expect(find.text(skiaPerfText), findsOneWidget);
      await tester.tap(find.text(skiaPerfText));
      await tester.pump();

      expect(urlLauncher.launches, isNotEmpty);
      expect(urlLauncher.launches.single, 'https://flutter-engine-perf.skia.org/');
    });

    testWidgets('source code opens github cocoon url', (WidgetTester tester) async {
      configureView(tester.view);
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardNavigationDrawer(),
        ),
      );

      expect(find.text('Source Code'), findsOneWidget);
      await tester.tap(find.text('Source Code'));
      await tester.pump();

      expect(urlLauncher.launches, isNotEmpty);
      expect(urlLauncher.launches.single, 'https://github.com/flutter/cocoon');
    });

    testWidgets('current route shows highlighted', (WidgetTester tester) async {
      configureView(tester.view);
      await tester.pumpWidget(const FakeInserter(child: MyApp()));

      void test({required bool isHome}) {
        final ListTile build = tester.widget(find.ancestor(of: find.text('Build'), matching: find.byType(ListTile)));
        expect(build.selected, !isHome);
      }

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(); // start animation of drawer opening
      await tester.pump(const Duration(seconds: 1)); // end animation of drawer opening
      test(isHome: false);

      await tester.tap(find.text('Build'));
      await tester.pump(); // drawer closes and new page arrives
      await tester.pump(const Duration(seconds: 1)); // end of those animations

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(); // start animation of drawer opening
      await tester.pump(const Duration(seconds: 1)); // end animation of drawer opening
      test(isHome: false);
    });
  });
}

/// Class for testing interactions on [NavigatorObserver].
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
