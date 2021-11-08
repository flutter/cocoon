// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String textToDisplay = 'Click to open the link';
  const String url = 'https://flutter.dev';
  const String uri = '/testDirectory/test';
  const MethodChannel channel = MethodChannel('plugins.flutter.io/url_launcher');

  group('urlButton tests', () {
    testWidgets('urlButton can launch a URL', (WidgetTester tester) async {
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: UrlButton(textToDisplay: textToDisplay, isURL: true, urlOrUri: url),
          ),
        ),
      );

      expect(find.text(textToDisplay), findsOneWidget);
      await tester.tap(find.byType(UrlButton));
      await tester.pumpAndSettle();

      // package:url_launcher is expected to throw an exception in test
      tester.takeException();
      expect(
        log,
        <Matcher>[
          isMethodCall('canLaunch', arguments: <String, Object>{
            'url': url,
          })
        ],
      );
    });

    testWidgets('urlButton can launch a URI', (WidgetTester tester) async {
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: UrlButton(textToDisplay: textToDisplay, isURL: false, urlOrUri: uri),
          ),
        ),
      );

      expect(find.text(textToDisplay), findsOneWidget);
      await tester.tap(find.byType(UrlButton));
      await tester.pumpAndSettle();

      // package:url_launcher is expected to throw an exception in test
      tester.takeException();
      expect(
        log,
        <Matcher>[
          isMethodCall('canLaunch', arguments: <String, Object>{
            'url': 'file://$uri',
          })
        ],
      );
    });
  });
}
