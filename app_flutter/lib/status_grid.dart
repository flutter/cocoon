// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'result_box.dart';

class StatusGrid extends StatelessWidget {
  static const int taskCount = 80; // rough estimate based on existing dashboard
  static const int commitCount = 200; // based on existing dashboard

  @override
  Widget build(BuildContext context) {
    /// There are too many columns to fit in one screen width
    return CustomScrollView(
      slivers: <Widget>[
        /// SliverGrid only renders the cells that are visible to the screen.
        SliverGrid.extent(
          children: List.generate(taskCount * commitCount, (index) {
            String randomMessage =
                ResultBox.resultColor.keys.toList()[4 * (index & 1)];
            return ResultBox(message: randomMessage);
          }),
          maxCrossAxisExtent: 40,
        ),
        // SliverGrid(
        //   // this technique was good for defining a size they should match
        //   // gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        //   //   maxCrossAxisExtent: 50.0,
        //   //   mainAxisSpacing: 1.0,
        //   //   crossAxisSpacing: 1.0,
        //   // ),
        //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //       mainAxisSpacing: 4, crossAxisCount: taskCount),
        //   delegate: SliverChildBuilderDelegate(
        //     (BuildContext context, int index) {
        //       // TODO(chillers): use a data source
        //       String randomMessage =
        //           ResultBox.resultColor.keys.toList()[4 * (index & 1)];
        //       return ResultBox(message: randomMessage);
        //     },
        //     // TODO(chillers): use a data source
        //     childCount: commitCount * taskCount,
        //   ),
        // ),
      ],
    );
  }
}
