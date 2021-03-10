// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cocoon_service/models.dart' show Task;

/// Show information regarding each attempt for a luci Task.
///
/// Currently shows a button that links to each individual log
/// for a Task.
class LuciTaskAttemptSummary extends StatelessWidget {
  const LuciTaskAttemptSummary({
    Key key,
    this.task,
  }) : super(key: key);

  /// The task to show information from.
  final Task task;

  @visibleForTesting
  static const String luciProdLogBase = 'https://ci.chromium.org/p/flutter/builders/prod/';

  @override
  Widget build(BuildContext context) {
    final List<String> buildNumberList = task.buildNumberList.isEmpty ? <String>[] : task.buildNumberList.split(',');
    return ListBody(
      children: List<Widget>.generate(buildNumberList.length, (int i) {
        return ElevatedButton(
          child: Text('OPEN LOG FOR BUILD #${buildNumberList[i]}'),
          onPressed: () => launch(_luciProdLogUrl(task.builderName, buildNumberList[i])),
        );
      }),
    );
  }

  String _luciProdLogUrl(String builderName, String buildNumber) {
    return '$luciProdLogBase$builderName/$buildNumber';
  }
}
