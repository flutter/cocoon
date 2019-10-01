// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Stage;

/// Displays information from a [Stage].
///
/// Shows a question mark for unknown stages.
class StageBox extends StatelessWidget {
  const StageBox({Key key, @required this.stage}) : super(key: key);

  /// [Stage] to show information from.
  final Stage stage;

  static const String stageCirrus = 'cirrus';
  static const String stageLuci = 'chromebot';
  static const String stageDevicelab = 'devicelab';
  static const String stageDevicelabWin = 'devicelab_win';
  static const String stageDevicelabMac = 'devicelab_mac';

  static Map<String, Widget> stageIcons = <String, Widget>{
    // SVG is not supported yet by Flutter, flutter_svg adds support
    // however, flutter_svg does not support web yet
    stageCirrus: Image.asset('assets/cirrus.svg'),
    // stageCirrus: Image.asset('assets/appveyor.png'),
    stageLuci: Image.asset('assets/chromium.svg'),
    stageDevicelab: Image.asset('assets/android.svg'),
    stageDevicelabWin: Image.asset('assets/windows.svg'),
    stageDevicelabMac: Image.asset('assets/apple.svg'),
  };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: stage.name,
      child: Container(
        margin: const EdgeInsets.all(1.0),
        child: stageIcons.containsKey(stage.name)
            ? stageIcons[stage.name]
            : Icon(Icons.help),
        width: 100,
        height: 100,
      ),
    );
  }
}
