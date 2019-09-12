// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Parent widget for an individual result.
///
/// Shows a black box for unknown messages.
class ResultBox extends StatelessWidget {
  const ResultBox({Key key, @required this.message}) : super(key: key);

  // TODO(chillers): Make this an enum
  final String message;

  /// A lookup table to define the background color for this ResultBox.
  ///
  /// The result messages are based on the messages the backend sends.
  static const _resultColor = <String, Color>{
    'Failed': Colors.red,
    'In Progress': Colors.purple, // v1 used the 'New' color while spinning
    'New': Colors.blue,
    'Skipped': Colors.white,
    'Succeeded': Colors.green,
    'Underperformed': Colors.orange,
  };

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
