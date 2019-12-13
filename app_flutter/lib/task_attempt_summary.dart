// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:cocoon_service/protos.dart' show Task;
import 'package:url_launcher/url_launcher.dart';

///
class TaskAttemptSummary extends StatelessWidget {
  const TaskAttemptSummary({this.task});

  /// The task to show information from.
  final Task task;

  static const String _cloudProjectId = 'flutter-dashboard';

  @visibleForTesting

  /// explain the breakdown of this url
  /// resource=global
  /// expandAll=false
  /// minLogLevel=false
  /// interval=NO_LIMIT
  /// dateRangeUnbound=backwardInTime
  static const String stackdriverLogUrlBase =
      'https://console.cloud.google.com/logs/viewer?project=$_cloudProjectId&resource=global&minLogLevel=0&expandAll=false&interval=NO_LIMIT&dateRangeUnbound=backwardInTime&logName=projects%2F$_cloudProjectId%2Flogs%2F';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: task.attempts * 50.0,
      child: ListView(
        children: List<Widget>.generate(task.attempts, (int i) {
          final int attemptNumber = i + 1; // attempts start at 1, not 0
          return FlatButton(
            child: Text('Log for Attempt #$attemptNumber'),
            // If the given task attempt does not exist, such as in profile mode, it will redirect to show all logs.
            onPressed: () => launch(_stackdriverUrl(task, attemptNumber)),
          );
        }),
      ),
    );
  }

  String _stackdriverUrl(Task task, int attemptNumber) {
    return '$stackdriverLogUrlBase${task.key.namespace}_$attemptNumber';
  }
}
