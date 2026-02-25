// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/build_log_url.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Show information regarding each attempt for a luci Task.
///
/// Currently shows a button that links to each individual log
/// for a Task.
class LuciTaskAttemptSummary extends StatelessWidget {
  const LuciTaskAttemptSummary({super.key, required this.task});

  /// The task to show information from.
  final Task task;

  @override
  Widget build(BuildContext context) {
    return ListBody(
      children: List<Widget>.generate(task.buildNumberList.length, (int i) {
        final buildNumber = task.buildNumberList[i];
        return ElevatedButton(
          child: Text('OPEN LOG FOR BUILD #$buildNumber'),
          onPressed: () async {
            final url = generateBuildLogUrl(
              buildName: task.builderName,
              buildNumber: buildNumber,
              isBringup: task.isBringup,
            );
            await launchUrl(Uri.parse(url));
          },
        );
      }),
    );
  }
}
