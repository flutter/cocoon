// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef DynamicFuture = Future<dynamic> Function();

/// The continue button of each step.
///
/// [elevatedButtonKey] is assigned to [ElevatedButton]. It makes locating and
/// pressing the button easier in tests.
///
/// [error] is the error string that gets displayed when there is an error in the release.
/// procedure. The error text is in red and displayed above [ElevatedButton].
///
/// When [enabled] is true, [ElevatedButton] is enabled, disabled otherwise.
///
/// [onPressedCallback] will be executed when [ElevatedButton] is enabled and pressed.
/// [onPressedCallback] must be asynchronous.
///
/// when [isLoading] is true, [CircularProgressIndicator] will be dispalyed, hidden otherwise.
class ContinueButton extends StatelessWidget {
  const ContinueButton({
    Key? key,
    required this.elevatedButtonKey,
    this.error,
    required this.enabled,
    required this.onPressedCallback,
    required this.isLoading,
  }) : super(key: key);

  final Key elevatedButtonKey;
  final String? error;
  final bool enabled;
  final DynamicFuture onPressedCallback;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (error != null)
          Center(
            child: SelectableText(
              error!,
              style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              key: elevatedButtonKey,
              onPressed: enabled == true
                  ? () async {
                      await onPressedCallback();
                    }
                  : null,
              child: const Text('Continue'),
            ),
            const SizedBox(width: 30.0),
            if (isLoading)
              const CircularProgressIndicator(
                semanticsLabel: 'Linear progress indicator',
              ),
          ],
        ),
      ],
    );
  }
}