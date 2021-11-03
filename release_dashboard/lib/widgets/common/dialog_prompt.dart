// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Widget that prompts an alert dialogue to the current window and forces the user to choose between two options.
Future<String?> dialogPrompt({
  required BuildContext context,
  required String title,
  required String content,
  required String leftOptionTitle,
  required String rightOptionTitle,
  VoidCallback? leftOptionCallback,
  VoidCallback? rightOptionCallback,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            if (leftOptionCallback != null) leftOptionCallback();
            Navigator.pop(context, leftOptionTitle);
          },
          child: Text(leftOptionTitle),
        ),
        TextButton(
          onPressed: () {
            if (rightOptionCallback != null) rightOptionCallback();
            Navigator.pop(context, rightOptionTitle);
          },
          child: Text(rightOptionTitle),
        ),
      ],
    ),
  );
}
