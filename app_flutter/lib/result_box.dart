// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Parent widget for an individual result.
///
/// Shows a black box for unknown messages.
class ResultBox extends StatelessWidget {
  ResultBox({Key key, @required this.message}) : super(key: key);

  final String message;

  /// A lookup table to define the background color for this ResultBox.
  ///
  /// The result messages are based on the messages the backend sends.
  final Map<String, Color> _resultColor = Map.fromEntries([
    MapEntry('Failed', Colors.red),
    MapEntry(
        'In Progress', Colors.purple), // v1 used the 'New' color while spinning
    MapEntry('New', Colors.blue),
    MapEntry('Skipped', Colors.white),
    MapEntry('Succeeded', Colors.green),
    MapEntry('Underperformed', Colors.orange),
  ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      color: _resultColor.containsKey(message)
          ? _resultColor[message]
          : Colors.black,
      width: 20,
      height: 20,
    );
  }
}
