// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'benchmarks.dart';
import 'framework.dart';
import 'utils.dart';

Task createAnalyzerCliTest({
  @required String sdk,
  @required String commit,
  @required DateTime timestamp
}) {
  return new AnalyzerCliTask(sdk, commit, timestamp);
}

Task createAnalyzerServerTest({
  @required String sdk,
  @required String commit,
  @required DateTime timestamp
}) {
  return new AnalyzerServerTask(sdk, commit, timestamp);
}

abstract class AnalyzerTask extends Task {
  AnalyzerTask(String name) : super(name);

  Benchmark benchmark;

  @override
  Future<TaskResultData> run() async {
    section(benchmark.name);
    await runBenchmark(benchmark, iterations: 3, warmUpBenchmark: true);
    return benchmark.bestResult;
  }
}

class AnalyzerCliTask extends AnalyzerTask {
  AnalyzerCliTask(String sdk, String commit, DateTime timestamp) : super('analyzer_cli__analysis_time') {
    this.benchmark = new FlutterAnalyzeBenchmark(onCancel, sdk, commit, timestamp);
  }
}

class AnalyzerServerTask extends AnalyzerTask {
  AnalyzerServerTask(String sdk, String commit, DateTime timestamp) : super('analyzer_server__analysis_time') {
    this.benchmark = new FlutterAnalyzeAppBenchmark(onCancel, sdk, commit, timestamp);
  }
}

class FlutterAnalyzeBenchmark extends Benchmark {
  FlutterAnalyzeBenchmark(Future<Null> onCancel, this.sdk, this.commit, this.timestamp)
    : super('flutter analyze --flutter-repo', onCancel);

  final String sdk;
  final String commit;
  final DateTime timestamp;

  File get benchmarkFile => file(path.join(config.flutterDirectory.path, 'analysis_benchmark.json'));

  @override
  TaskResultData get lastResult => new TaskResultData.fromFile(benchmarkFile);

  @override
  Future<num> run() async {
    rm(benchmarkFile);
    await inDirectory(config.flutterDirectory, () async {
      await flutter('analyze', onCancel, options: ['--flutter-repo', '--benchmark']);
    });
    return addBuildInfo(benchmarkFile, timestamp: timestamp, expected: 25.0, sdk: sdk, commit: commit);
  }
}

class FlutterAnalyzeAppBenchmark extends Benchmark {
  FlutterAnalyzeAppBenchmark(Future<Null> onCancel, this.sdk, this.commit, this.timestamp)
    : super('analysis server mega_gallery', onCancel);

  final String sdk;
  final String commit;
  final DateTime timestamp;

  @override
  TaskResultData get lastResult => new TaskResultData.fromFile(benchmarkFile);

  Directory get megaDir => dir(path.join(config.flutterDirectory.path, 'dev/benchmarks/mega_gallery'));
  File get benchmarkFile => file(path.join(megaDir.path, 'analysis_benchmark.json'));

  Future<Null> init() {
    return inDirectory(config.flutterDirectory, () async {
      await dart(['dev/tools/mega_gallery.dart'], onCancel);
    });
  }

  @override
  Future<num> run() async {
    rm(benchmarkFile);
    await inDirectory(megaDir, () async {
      await flutter('analyze', onCancel, options: ['--watch', '--benchmark']);
    });
    return addBuildInfo(benchmarkFile, timestamp: timestamp, expected: 10.0, sdk: sdk, commit: commit);
  }
}
