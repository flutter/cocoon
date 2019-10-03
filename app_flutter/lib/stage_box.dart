// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Task;

/// Displays information from a [Stage].
///
/// Shows a question mark for unknown stages.
class StageBox extends StatelessWidget {
  const StageBox({Key key, @required this.task}) : super(key: key);

  /// [Stage] to show information from.
  final Task task;

  static const String stageCirrus = 'cirrus';
  static const String stageLuci = 'chromebot';
  static const String stageDevicelab = 'devicelab';
  static const String stageDevicelabWin = 'devicelab_win';
  static const String stageDevicelabIOs = 'devicelab_ios';

  static Map<String, Widget> stageIcons = <String, Widget>{
    stageCirrus: Image.asset('assets/cirrus.png'),
    stageLuci: Image.asset('assets/chromium.png'),
    stageDevicelab: Image.asset('assets/android.png'),
    stageDevicelabWin: Image.asset('assets/windows.png'),
    stageDevicelabIOs: Image.asset('assets/apple.png'),
  };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${task.stageName}/${task.name}',
      child: Container(
        margin: const EdgeInsets.all(7.5),
        child: stageIcons.containsKey(task.stageName)
            ? stageIcons[task.stageName]
            : Icon(Icons.help),
        width: 100,
        height: 100,
      ),
    );
  }
}
