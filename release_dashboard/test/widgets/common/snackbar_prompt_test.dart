// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/common/snackbar_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String msg = 'This is the prompt message.';

  group('Snackbar prompt tests', () {
    testWidgets('Appears upon clicking on a button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  snackbarPrompt(
                    context: context,
                    msg: msg,
                  );
                },
                child: const Text('Clean'),
              );
            },
          ),
        ),
      ));

      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(msg), findsOneWidget);
    });

    testWidgets('Disappears when Ok is clicked', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  snackbarPrompt(
                    context: context,
                    msg: msg,
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
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
