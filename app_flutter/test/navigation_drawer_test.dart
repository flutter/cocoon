// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:app_flutter/navigation_drawer.dart';

void main() {
  group('NavigationDrawer', () {
    testWidgets('lists all pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationDrawer(),
        ),
      );

      expect(find.text('Build'), findsOneWidget);
      expect(find.text('Benchmarks'), findsOneWidget);
      expect(find.text('Repository'), findsOneWidget);
      expect(find.text('Infra Agents'), findsOneWidget);
      expect(find.text('Source Code'), findsOneWidget);
    });
    testWidgets('build navigates to build Flutter route', (WidgetTester tester) async {
      final MockNavigatorObserver navigatorObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: const NavigationDrawer(),
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

    testWidgets('infra agents navigates to its Flutter route', (WidgetTester tester) async {
      final MockNavigatorObserver navigatorObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: const NavigationDrawer(),
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/agents': (BuildContext context) => const Text('infra agents'),
          },
          navigatorObservers: <NavigatorObserver>[navigatorObserver],
        ),
      );

      verifyNever(navigatorObserver.didReplace());
      expect(find.text('infra agents'), findsNothing);

      // Click the nav link for infra agent
      await tester.tap(find.text('Infra Agents'));
      await tester.pumpAndSettle();

      verify(navigatorObserver.didReplace(newRoute: anyNamed('newRoute'), oldRoute: anyNamed('oldRoute'))).called(1);
      expect(find.text('infra agents'), findsOneWidget);
    });

    testWidgets('performance opens performance html url', (WidgetTester tester) async {
      const MethodChannel urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      urlLauncherChannel.setMockMethodCallHandler((MethodCall methodCall) async => log.add(methodCall));

      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationDrawer(),
        ),
      );

      expect(find.text('Benchmarks'), findsOneWidget);
      await tester.tap(find.text('Benchmarks'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': '/benchmarks.html',
            'useSafariVC': false,
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{}
          })
        ],
      );
    });

    testWidgets('skia perf opens skia perf url', (WidgetTester tester) async {
      const MethodChannel urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      urlLauncherChannel.setMockMethodCallHandler((MethodCall methodCall) async => log.add(methodCall));

      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationDrawer(),
        ),
      );

      const String skiaPerfText = 'Benchmarks on Skia Perf';
      expect(find.text(skiaPerfText), findsOneWidget);
      await tester.tap(find.text(skiaPerfText));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'https://flutter-perf.skia.org/',
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

    testWidgets('repository opens repository html url', (WidgetTester tester) async {
      const MethodChannel urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      urlLauncherChannel.setMockMethodCallHandler((MethodCall methodCall) async => log.add(methodCall));

      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationDrawer(),
        ),
      );

      expect(find.text('Repository'), findsOneWidget);
      await tester.tap(find.text('Repository'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': '/repository.html',
            'useSafariVC': false,
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{}
          })
        ],
      );
    });

    testWidgets('source code opens github cocoon url', (WidgetTester tester) async {
      const MethodChannel urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      urlLauncherChannel.setMockMethodCallHandler((MethodCall methodCall) async => log.add(methodCall));

      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationDrawer(),
        ),
      );

      expect(find.text('Source Code'), findsOneWidget);
      await tester.tap(find.text('Source Code'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'https://github.com/flutter/cocoon',
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

    testWidgets('current route shows highlighted', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationDrawer(
            currentRoute: '/build',
          ),
        ),
      );

      final ListTile selectedListTile = tester.widget(find.byKey(const Key('nav-link-build')));
      final ListTile notSelectedListTile = tester.widget(find.byKey(const Key('nav-link-benchmarks')));
      expect(selectedListTile.selected, true);
      expect(notSelectedListTile.selected, false);
    });
  });
}

/// Class for testing interactions on [NavigatorObserver].
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
