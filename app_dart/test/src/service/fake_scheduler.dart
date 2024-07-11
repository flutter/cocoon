// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:cocoon_service/src/service/build_bucket_client.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:github/github.dart';
import 'package:retry/retry.dart';

import '../utilities/entity_generators.dart';
import 'fake_luci_build_service.dart';

/// Fake for [Scheduler] to use for tests that rely on it.
class FakeScheduler extends Scheduler {
  FakeScheduler({
    this.ciYaml,
    LuciBuildService? luciBuildService,
    BuildBucketClient? buildbucket,
    required super.config,
    GithubChecksUtil? githubChecksUtil,
  }) : super(
          cache: CacheService(inMemory: true),
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: githubChecksUtil,
          ),
          luciBuildService: luciBuildService ??
              FakeLuciBuildService(
                config: config,
                buildBucketClient: buildbucket,
                githubChecksUtil: githubChecksUtil,
              ),
        );

  final CiYaml _defaultConfig = emptyConfig;

  /// [CiYaml] value to be injected on [getCiYaml].
  CiYaml? ciYaml;

  /// If true, getCiYaml will throw a [FormatException] when validation is
  /// enforced, simulating failing validation.
  bool failCiYamlValidation = false;

  @override
  Future<CiYaml> getCiYaml(
    Commit commit, {
    CiYaml? totCiYaml,
    RetryOptions? retryOptions,
    bool validate = false,
  }) async {
    if (validate && failCiYamlValidation) {
      throw const FormatException('Failed validation!');
    }
    return ciYaml ?? _defaultConfig;
  }

  @override
  Future<Commit> generateTotCommit({required String branch, required RepositorySlug slug}) async {
    return generateCommit(1);
  }

  int cancelPreSubmitTargetsCallCnt = 0;

  int get cancelPreSubmitTargetsCallCount => cancelPreSubmitTargetsCallCnt;

  void resetCancelPreSubmitTargetsCallCount() => cancelPreSubmitTargetsCallCnt = 0;

  @override
  Future<void> cancelPreSubmitTargets({
    required PullRequest pullRequest,
    String reason = 'Newer commit available',
  }) async {
    await super.cancelPreSubmitTargets(pullRequest: pullRequest);
    cancelPreSubmitTargetsCallCnt++;
  }

  int triggerPresubmitTargetsCnt = 0;

  int get triggerPresubmitTargetsCallCount => triggerPresubmitTargetsCnt;

  void resetTriggerPresubmitTargetsCallCount() => triggerPresubmitTargetsCnt = 0;

  @override
  Future<void> triggerPresubmitTargets({
    required PullRequest pullRequest,
    String reason = 'Newer commit available',
    List<String>? builderTriggerList,
  }) async {
    await super.triggerPresubmitTargets(pullRequest: pullRequest);
    triggerPresubmitTargetsCnt++;
  }

  int addPullRequestCallCnt = 0;

  int get addPullRequestCallCount {
    return addPullRequestCallCnt;
  }

  void resetAddPullRequestCallCount() {
    addPullRequestCallCnt = 0;
  }

  @override
  Future<void> addPullRequest(
    PullRequest pr,
  ) async {
    await super.addPullRequest(pr);
    addPullRequestCallCnt++;
  }
}

final CiYaml emptyConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux A',
        scheduler: pb.SchedulerSystem.luci,
      ),
    ],
  ),
);

CiYaml exampleConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux A',
        scheduler: pb.SchedulerSystem.luci,
      ),
      pb.Target(
        name: 'Mac A',
        scheduler: pb.SchedulerSystem.luci,
      ),
      pb.Target(
        name: 'Windows A',
        scheduler: pb.SchedulerSystem.luci,
      ),
      pb.Target(
        name: 'Google Internal Roll',
        presubmit: false,
        postsubmit: true,
        scheduler: pb.SchedulerSystem.google_internal,
      ),
    ],
  ),
);

CiYaml exampleFlakyConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Flaky 1',
        scheduler: pb.SchedulerSystem.luci,
        properties: {
          'flakiness_threshold': '0.04',
        },
      ),
      pb.Target(
        name: 'Flaky Skip',
        scheduler: pb.SchedulerSystem.luci,
        properties: {
          'ignore_flakiness': 'true',
        },
      ),
    ],
  ),
);

CiYaml exampleBackfillConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux A',
        scheduler: pb.SchedulerSystem.luci,
        postsubmit: true,
        properties: {'backfill': 'true'},
      ),
      pb.Target(
        name: 'Mac A',
        scheduler: pb.SchedulerSystem.luci,
        postsubmit: true,
      ),
      pb.Target(
        name: 'Windows A',
        scheduler: pb.SchedulerSystem.luci,
        postsubmit: true,
        properties: {'backfill': 'false'},
      ),
    ],
  ),
);

CiYaml examplePresubmitRescheduleConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux A',
      ),
      pb.Target(
        name: 'Linux B',
        postsubmit: true,
        properties: {'presubmit_retry': '1'},
      ),
    ],
  ),
);

final CiYaml batchPolicyConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux_android A',
      ),
      pb.Target(
        name: 'Linux_android B',
      ),
      pb.Target(
        name: 'Linux_android C',
      ),
    ],
  ),
);

final CiYaml unsupportedPostsubmitCheckrunConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux flutter',
      ),
    ],
  ),
);

final CiYaml nonBringupPackagesConfig = CiYaml(
  slug: Config.packagesSlug,
  branch: Config.defaultBranch(Config.packagesSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.packagesSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux nonbringup',
      ),
    ],
  ),
);

final CiYaml bringupPackagesConfig = CiYaml(
  slug: Config.packagesSlug,
  branch: Config.defaultBranch(Config.packagesSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.packagesSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux bringup',
        bringup: true,
      ),
    ],
  ),
);

final CiYaml totCiYaml = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux_android B',
      ),
      pb.Target(
        name: 'Linux_android C',
      ),
    ],
  ),
);

final CiYaml notInToTConfig = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Linux_android A',
      ),
    ],
  ),
  totConfig: totCiYaml,
);
