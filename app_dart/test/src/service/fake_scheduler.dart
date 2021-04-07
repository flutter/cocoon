// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'package:cocoon_service/src/datastore/config.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pb.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/service/scheduler.dart';

import '../request_handling/fake_logging.dart';

/// Fake for [Scheduler] to use for tests that rely on it.
class FakeScheduler extends Scheduler {
  FakeScheduler({
    this.schedulerConfig,
    this.devicelabManifest = 'tasks:',
    Config config,
  }) : super(
          config: config,
          log: FakeLogging(),
        );

  /// [SchedulerConfig] value to be injected on [getSchedulerConfig].
  SchedulerConfig schedulerConfig;

  /// String contents of [Manifest] for legacy devicelab tasks.
  String devicelabManifest;

  @override
  Future<YamlMap> loadDevicelabManifest(Commit commit) async => await loadYaml(devicelabManifest) as YamlMap;
}
