// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/is_dart_internal.dart';
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

  @visibleForTesting
  static const String luciProdLogBase =
      'https://ci.chromium.org/p/flutter/builders';

  @visibleForTesting
  static const String dartInternalLogBase =
      'https://ci.chromium.org/p/dart-internal/builders';

  @override
  Widget build(BuildContext context) {
    return ListBody(
      children: List<Widget>.generate(task.buildNumberList.length, (int i) {
        return ElevatedButton(
          child: Text('OPEN LOG FOR BUILD #${task.buildNumberList[i]}'),
          onPressed: () async {
            if (isTaskFromDartInternalBuilder(builderName: task.builderName)) {
              await launchUrl(
                _dartInternalLogUrl(task.builderName, task.buildNumberList[i]),
              );
            } else {
              await launchUrl(
                _luciProdLogUrl(task.builderName, task.buildNumberList[i]),
              );
            }
          },
        );
      }),
    );
  }

  Uri _luciProdLogUrl(String builderName, int buildNumber) {
    final pool = task.isBringup ? 'staging' : 'prod';
    return Uri.parse('$luciProdLogBase/$pool/$builderName/$buildNumber');
  }

  Uri _dartInternalLogUrl(String builderName, int buildNumber) {
    return Uri.parse('$dartInternalLogBase/flutter/$builderName/$buildNumber');
  }
}
