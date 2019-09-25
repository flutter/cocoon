// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;
import 'package:flutter/material.dart';

import 'commit_box.dart';
import 'task_box.dart';

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  const StatusGrid({Key key, @required this.statuses}) : super(key: key);

  final List<CommitStatus> statuses;

  @override
  Widget build(BuildContext context) {
    int columnCount = _getColumnCount(statuses);

    // The grid is wrapped with SingleChildScrollView to enable scrolling both
    // horizontally and vertically
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: columnCount * 50.0,
          child: GridView.builder(
            itemCount: columnCount * statuses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount),
            itemBuilder: (BuildContext context, int index) {
              int commitStatusIndex = (index / columnCount).floor();
              if (index % columnCount == 0) {
                return CommitBox(commit: statuses[commitStatusIndex].commit);
              }

              return TaskBox(task: Task()..status = 'Succeeded');
            },
          ),
        ),
      ),
    );
  }

  int _getColumnCount(List<CommitStatus> statuses) {
    int columnCount = 1; // start at 1 to include [CommitBox]
    CommitStatus catCalledForJuryDuty = statuses.first;
    for (Stage stage in catCalledForJuryDuty.stages) {
      columnCount += stage.tasks.length;
    }

    return columnCount;
  }
}
