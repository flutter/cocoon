// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'commit_box.dart';
import 'result_box.dart';

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  const StatusGrid({Key key}) : super(key: key);

  static const int columnCount =
      81; // rough estimate based on existing dashboard
  static const int commitCount = 200;

  @override
  Widget build(BuildContext context) {
    // The grid is wrapped with SingleChildScrollView to enable scrolling both
    // horizontally and vertically
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: columnCount * 50.0,
          // height: MediaQuery.of(context).size.height,
          child: GridView.builder(
            // TODO(chillers): implement custom scroll physics to match horizontal scroll
            itemCount: columnCount * commitCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount),
            itemBuilder: (BuildContext context, int index) {
              // TODO(chillers): Use StageModel data
              if (index % columnCount == 0) {
                return CommitBox(
                  message: 'commit #$index',
                  author: 'author #$index',
                  avatarUrl:
                      'https://avatars2.githubusercontent.com/u/2148558?v=4',
                );
              }

              return ResultBox(message: 'Succeeded');
            },
          ),
        ),
      ),
    );
  }
}
