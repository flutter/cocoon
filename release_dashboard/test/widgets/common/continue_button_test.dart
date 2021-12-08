// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/common/continue_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Key buttonKey = Key('testButton');
  const String errorMsg = 'There is an error';

  group('Continue button tests', () {
    testWidgets('Renders elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ContinueButton(
              elevatedButtonKey: buttonKey,
              enabled: true,
              onPressedCallback: () async {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byKey(buttonKey), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
      expect(tester.widget<ElevatedButton>(find.byKey(buttonKey)).enabled, equals(true));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Display the error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ContinueButton(
              elevatedButtonKey: buttonKey,
              error: errorMsg,
              enabled: true,
              onPressedCallback: () async {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text(errorMsg), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('Disable the button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ContinueButton(
              elevatedButtonKey: buttonKey,
              enabled: false,
              onPressedCallback: () async {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byKey(buttonKey)).enabled, equals(false));
    });

    testWidgets('Display the loading widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ContinueButton(
              elevatedButtonKey: buttonKey,
              enabled: true,
              onPressedCallback: () async {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Execute onPressedCallback if button is enabled', (WidgetTester tester) async {
      bool callbackExecuted = false;
      Future<void> onPressedCallback() async {
        callbackExecuted = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ContinueButton(
              elevatedButtonKey: buttonKey,
              enabled: true,
              onPressedCallback: onPressedCallback,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();
      expect(callbackExecuted, true);
    });
  });
}
