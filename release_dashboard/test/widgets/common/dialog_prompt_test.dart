// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/common/dialog_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String title = 'Are you sure you want to clean up the persistent state file?';
  const String content = 'This will abort a work in progress release.';
  const String leftOption = 'Yes';
  const String rightOption = 'No';

  group('Dialog prompt UI tests', () {
    testWidgets('Appears upon clicking on a button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  dialogPrompt(
                    context: context,
                    title: title,
                    content: content,
                    leftOptionTitle: leftOption,
                    rightOptionTitle: rightOption,
                  );
                },
                child: const Text('Clean'),
              );
            },
          ),
        ),
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.text(content), findsOneWidget);
      expect(find.text(leftOption), findsOneWidget);
      expect(find.text(rightOption), findsOneWidget);
    });

    testWidgets('Disappears when the left option is clicked', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  dialogPrompt(
                    context: context,
                    title: title,
                    content: content,
                    leftOptionTitle: leftOption,
                    rightOptionTitle: rightOption,
                  );
                },
                child: const Text('Clean'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(leftOption));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Disappears when the right option is clicked', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  dialogPrompt(
                    context: context,
                    title: title,
                    content: content,
                    leftOptionTitle: leftOption,
                    rightOptionTitle: rightOption,
                  );
                },
                child: const Text('Clean'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(rightOption));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('dialog prompt callback tests', () {
    testWidgets('Executes the left option callback when the left option is clicked', (WidgetTester tester) async {
      bool isLeftCallbackCalled = false;
      void leftCallbackTest() {
        isLeftCallbackCalled = true;
      }

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  dialogPrompt(
                    context: context,
                    title: title,
                    content: content,
                    leftOptionTitle: leftOption,
                    rightOptionTitle: rightOption,
                    leftOptionCallback: leftCallbackTest,
                  );
                },
                child: const Text('Clean'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(leftOption));
      await tester.pumpAndSettle();
      expect(isLeftCallbackCalled, equals(true));
    });

    testWidgets('Executes the right option callback when the right option is clicked', (WidgetTester tester) async {
      bool isRightCallbackCalled = false;
      void rightCallbackTest() {
        isRightCallbackCalled = true;
      }

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  dialogPrompt(
                    context: context,
                    title: title,
                    content: content,
                    leftOptionTitle: leftOption,
                    rightOptionTitle: rightOption,
                    rightOptionCallback: rightCallbackTest,
                  );
                },
                child: const Text('Clean'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(rightOption));
      await tester.pumpAndSettle();
      expect(isRightCallbackCalled, equals(true));
    });
  });
}
