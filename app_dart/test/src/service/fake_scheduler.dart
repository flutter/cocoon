// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/proto/protos.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:retry/retry.dart';

import '../request_handling/fake_logging.dart';
import 'fake_luci_build_service.dart';

/// Fake for [Scheduler] to use for tests that rely on it.
class FakeScheduler extends Scheduler {
  FakeScheduler({
    this.schedulerConfig,
    LuciBuildService? luciBuildService,
    BuildBucketClient? buildbucket,
    required Config config,
    GithubChecksUtil? githubChecksUtil,
  }) : super(
          cache: CacheService(inMemory: true),
          config: config,
          githubChecksService: GithubChecksService(config, githubChecksUtil: githubChecksUtil),
          luciBuildService: luciBuildService ??
              FakeLuciBuildService(config, buildbucket: buildbucket, githubChecksUtil: githubChecksUtil),
        ) {
    setLogger(FakeLogging());
  }

  final SchedulerConfig _defaultConfig = emptyConfig;

  /// [SchedulerConfig] value to be injected on [getSchedulerConfig].
  SchedulerConfig? schedulerConfig;

  @override
  Future<SchedulerConfig> getSchedulerConfig(Commit commit, {RetryOptions? retryOptions}) async =>
      schedulerConfig ?? _defaultConfig;
}

final SchedulerConfig emptyConfig = SchedulerConfig(
  enabledBranches: <String>['master'],
  targets: <Target>[],
);

SchedulerConfig exampleConfig = SchedulerConfig(enabledBranches: <String>[
  'master'
], targets: <Target>[
  Target(
    bringup: false,
    name: 'Linux A',
    scheduler: SchedulerSystem.luci,
    presubmit: true,
    postsubmit: true,
  ),
  Target(
    bringup: false,
    name: 'Google Internal Roll',
    presubmit: false,
    postsubmit: true,
    scheduler: SchedulerSystem.google_internal,
  ),
]);
