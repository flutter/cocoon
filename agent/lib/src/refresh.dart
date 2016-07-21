// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'adb.dart';
import 'benchmarks.dart';
import 'framework.dart';
import 'utils.dart';

Task createRefreshTest({
  String commit,
  DateTime timestamp
}) => new EditRefreshTask(commit, timestamp);

class EditRefreshTask extends Task {
  EditRefreshTask(this.commit, this.timestamp)
      : super('mega_gallery__refresh_time') {
    assert(commit != null);
    assert(timestamp != null);
  }

  final String commit;
  final DateTime timestamp;

  @override
  Future<TaskResultData> run() async {
    adb().unlock();
    Benchmark benchmark = new EditRefreshBenchmark(commit, timestamp, onCancel);
    section(benchmark.name);
    await runBenchmark(benchmark, iterations: 3, warmUpBenchmark: true);
    return benchmark.bestResult;
  }
}

class EditRefreshBenchmark extends Benchmark {
  EditRefreshBenchmark(this.commit, this.timestamp, Future<Null> onCancel)
      : super('edit refresh', onCancel);

  final String commit;
  final DateTime timestamp;

  Directory get megaDir => dir(path.join(config.flutterDirectory.path, 'dev/benchmarks/mega_gallery'));
  File get benchmarkFile => file(path.join(megaDir.path, 'refresh_benchmark.json'));

  @override
  TaskResultData get lastResult => new TaskResultData.fromFile(benchmarkFile);

  Future<Null> init() {
    return inDirectory(config.flutterDirectory, () async {
      await dart(['dev/tools/mega_gallery.dart'], onCancel);
    });
  }

  @override
  Future<num> run() async {
    rm(benchmarkFile);
    int exitCode = await inDirectory(megaDir, () async {
      return await flutter(
        'run', onCancel, options: ['-d', config.androidDeviceId, '--resident', '--benchmark'], canFail: true
      );
    });
    if (exitCode != 0)
      return new Future.error(exitCode);
    return addBuildInfo(benchmarkFile, timestamp: timestamp, expected: 200, commit: commit);
  }
}
