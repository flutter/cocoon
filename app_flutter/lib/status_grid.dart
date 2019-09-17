// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'result_box.dart';

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  const StatusGrid({Key key}) : super(key: key);

  static const int taskCount = 80; // rough estimate based on existing dashboard
  static const int commitCount = 50;

  @override
  Widget build(BuildContext context) {
    // The grid is wrapped with SingleChildScrollView to enable scrolling both
    // horizontally and vertically
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: taskCount * 50.0,
        height: 500.0,
        child: GridView.count(
          // TODO(chillers)L implement custom scroll physics to match horizontal scroll
          crossAxisCount: taskCount,
          // TODO(chillers): Use result data
          children: List.generate(taskCount * commitCount, (index) {
            return ResultBox(message: 'Succeeded');
          }),
        ),
      ),
    );
  }
}
