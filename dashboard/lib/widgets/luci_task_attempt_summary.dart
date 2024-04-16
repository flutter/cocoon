// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/qualified_task.dart';
import '../model/task_firestore.pb.dart';

/// Show information regarding each attempt for a luci Task.
///
/// Currently shows a button that links to each individual log
/// for a Task.
class LuciTaskAttemptSummary extends StatelessWidget {
  const LuciTaskAttemptSummary({
    super.key,
    required this.task,
  });

  /// The task to show information from.
  final TaskDocument task;

  @visibleForTesting
  static const String luciProdLogBase = 'https://ci.chromium.org/p/flutter/builders';

  @visibleForTesting
  static const String dartInternalLogBase = 'https://ci.chromium.org/p/dart-internal/builders';

  @override
  Widget build(BuildContext context) {
    // TODO: Need to handle case of multiple runs.
    // final List<String> buildNumberList = task.buildNumberList.isEmpty ? <String>[] : task.buildNumberList.split(',');
    final List<String> buildNumberList = task.hasBuildNumber() ? <String>[task.buildNumber.toString()] : <String>[];
    return ListBody(
      children: List<Widget>.generate(buildNumberList.length, (int i) {
        return ElevatedButton(
          child: Text('OPEN LOG FOR BUILD #${buildNumberList[i]}'),
          onPressed: () {
            if (dartInternalTasks.contains(task.taskName)) {
              launchUrl(_dartInternalLogUrl(task.taskName, buildNumberList[i]));
            } else {
              launchUrl(_luciProdLogUrl(task.taskName, buildNumberList[i]));
            }
          },
        );
      }),
    );
  }

  Uri _luciProdLogUrl(String builderName, String buildNumber) {
    final String pool = task.bringup ? 'staging' : 'prod';
    return Uri.parse('$luciProdLogBase/$pool/$builderName/$buildNumber');
  }

  Uri _dartInternalLogUrl(String builderName, String buildNumber) {
    return Uri.parse('$dartInternalLogBase/flutter/$builderName/$buildNumber');
  }
}
