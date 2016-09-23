// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'adb.dart';
import 'framework.dart';
import 'utils.dart';

Task createHotDevCycleTest({
  String commit,
  DateTime timestamp
}) => new HotDevCycleTask(commit, timestamp);

class HotDevCycleTask extends Task {
  HotDevCycleTask(this.commit, this.timestamp)
      : super('hot_mode_dev_cycle__benchmark') {
    assert(commit != null);
    assert(timestamp != null);
  }

  final String commit;
  final DateTime timestamp;

  Directory get appDir =>
      dir(path.join(config.flutterDirectory.path,
          'examples/flutter_gallery'));

  File get benchmarkFile =>
      file(path.join(appDir.path, 'hot_benchmark.json'));

  final List<String> benchmarkScoreKeys = [
    'hotReloadMillisecondsToFrame',
    'hotRestartMillisecondsToFrame'
  ];

  @override
  Future<TaskResultData> run() async {
    Device device = devices.workingDevice;
    device.unlock();
    rm(benchmarkFile);
    await inDirectory(appDir, () async {
      return await flutter(
        'run',
        options: ['--hot', '-d', device.deviceId, '--benchmark'],
        canFail: false
      );
    });
    return new TaskResultData.fromFile(benchmarkFile,
                                       benchmarkScoreKeys: benchmarkScoreKeys);
  }
}
