// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'adb.dart';
import 'framework.dart';
import 'utils.dart';

Task createComplexLayoutScrollPerfTest({ bool ios: false }) {
  return new PerfTest(
    'complex_layout_scroll_perf${ios ? "_ios" : ""}__timeline_summary',
    '${config.flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'complex_layout_scroll_perf',
    ios: ios
  );
}

Task createFlutterGalleryStartupTest({ bool ios: false }) {
  return new StartupTest(
    'flutter_gallery${ios ? "_ios" : ""}__start_up',
    '${config.flutterDirectory.path}/examples/flutter_gallery',
    ios: ios
  );
}

Task createComplexLayoutStartupTest({ bool ios: false }) {
  return new StartupTest(
    'complex_layout${ios ? "_ios" : ""}__start_up',
    '${config.flutterDirectory.path}/dev/benchmarks/complex_layout',
    ios: ios
  );
}

Task createFlutterGalleryBuildTest() {
  return new BuildTest('flutter_gallery__build', '${config.flutterDirectory.path}/examples/flutter_gallery');
}

Task createComplexLayoutBuildTest() {
  return new BuildTest('complex_layout__build', '${config.flutterDirectory.path}/dev/benchmarks/complex_layout');
}

/// Measure application startup performance.
class StartupTest extends Task {
  static const Duration _startupTimeout = const Duration(minutes: 2);

  StartupTest(String name, this.testDirectory, { this.ios }) : super(name);

  final String testDirectory;
  final bool ios;

  Future<TaskResultData> run() async {
    return await inDirectory(testDirectory, () async {
      String deviceId = devices.workingDevice.deviceId;
      await flutter('packages', options: ['get']);

      if (ios) {
        // This causes an Xcode project to be created.
        await flutter('build', options: ['ios', '--profile']);
      }

      await flutter('run', options: [
        '--profile',
        '--trace-startup',
        '-d',
        deviceId
      ]).timeout(_startupTimeout);
      Map<String, dynamic> data = JSON.decode(file('$testDirectory/build/start_up_info.json').readAsStringSync());
      return new TaskResultData(data, benchmarkScoreKeys: <String>[
        'engineEnterTimestampMicros',
        'timeToFirstFrameMicros',
      ]);
    });
  }
}

/// Measures application runtime performance, specifically per-frame
/// performance.
class PerfTest extends Task {

  PerfTest(String name, this.testDirectory, this.testTarget, this.timelineFileName, { this.ios })
      : super(name);

  final String testDirectory;
  final String testTarget;
  final String timelineFileName;
  final bool ios;

  @override
  Future<TaskResultData> run() {
    return inDirectory(testDirectory, () async {
      String deviceId = devices.workingDevice.deviceId;
      await flutter('packages', options: ['get']);

      if (ios) {
        // This causes an Xcode project to be created.
        await flutter('build', options: ['ios', '--profile']);
      }

      await flutter('drive', options: [
        '-v',
        '--profile',
        '--trace-startup', // Enables "endless" timeline event buffering.
        '-t',
        testTarget,
        '-d',
        deviceId,
      ]);
      Map<String, dynamic> data = JSON.decode(file('$testDirectory/build/${timelineFileName}.timeline_summary.json').readAsStringSync());
      return new TaskResultData(data, benchmarkScoreKeys: <String>[
        'average_frame_build_time_millis',
        'worst_frame_build_time_millis',
        'missed_frame_build_budget_count',
      ]);
    });
  }
}

class BuildTest extends Task {

  BuildTest(String name, this.testDirectory) : super(name);

  final String testDirectory;

  Future<TaskResultData> run() async {
    return await inDirectory(testDirectory, () async {
      Device device = devices.workingDevice;
      device.unlock();
      await flutter('packages', options: ['get']);

      var watch = new Stopwatch()..start();
      await flutter('build', options: [
        'aot',
        '--profile',
        '--no-pub',
        '--target-platform', 'android-arm'  // Generate blobs instead of assembly.
      ]);
      watch.stop();

      var vmisolateSize = file("$testDirectory/build/aot/snapshot_aot_vmisolate").lengthSync();
      var isolateSize = file("$testDirectory/build/aot/snapshot_aot_isolate").lengthSync();
      var instructionsSize = file("$testDirectory/build/aot/snapshot_aot_instr").lengthSync();
      var rodataSize = file("$testDirectory/build/aot/snapshot_aot_rodata").lengthSync();
      var totalSize = vmisolateSize + isolateSize + instructionsSize + rodataSize;

      Map<String, dynamic> data = {
        'aot_snapshot_build_millis': watch.elapsedMilliseconds,
        'aot_snapshot_size_vmisolate': vmisolateSize,
        'aot_snapshot_size_isolate': isolateSize,
        'aot_snapshot_size_instructions': instructionsSize,
        'aot_snapshot_size_rodata': rodataSize,
        'aot_snapshot_size_total': totalSize,
      };
      return new TaskResultData(data, benchmarkScoreKeys: <String>[
        'aot_snapshot_build_millis',
        'aot_snapshot_size_vmisolate',
        'aot_snapshot_size_isolate',
        'aot_snapshot_size_instructions',
        'aot_snapshot_size_rodata',
        'aot_snapshot_size_total',
      ]);
    });
  }
}
