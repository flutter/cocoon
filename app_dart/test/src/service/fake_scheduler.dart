// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:cocoon_service/src/service/build_bucket_client.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/get_files_changed.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:github/github.dart';

import 'fake_ci_yaml_fetcher.dart';
import 'fake_get_files_changed.dart';
import 'fake_luci_build_service.dart';

/// Fake for [Scheduler] to use for tests that rely on it.
class FakeScheduler extends Scheduler {
  FakeScheduler({
    LuciBuildService? luciBuildService,
    BuildBucketClient? buildbucket,
    GetFilesChanged? getFilesChanged,
    required super.config,
    GithubChecksUtil? githubChecksUtil,
    CiYamlFetcher? ciYamlFetcher,
  }) : super(
         cache: CacheService(inMemory: true),
         githubChecksService: GithubChecksService(
           config,
           githubChecksUtil: githubChecksUtil,
         ),
         getFilesChanged: getFilesChanged ?? FakeGetFilesChanged(),
         luciBuildService:
             luciBuildService ??
             FakeLuciBuildService(
               config: config,
               buildBucketClient: buildbucket,
               githubChecksUtil: githubChecksUtil,
             ),
         fusionTester: const FusionTester(),
         ciYamlFetcher: ciYamlFetcher ?? FakeCiYamlFetcher(),
       );

  int cancelPreSubmitTargetsCallCnt = 0;

  int get cancelPreSubmitTargetsCallCount => cancelPreSubmitTargetsCallCnt;

  void resetCancelPreSubmitTargetsCallCount() =>
      cancelPreSubmitTargetsCallCnt = 0;

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

  void resetTriggerPresubmitTargetsCallCount() =>
      triggerPresubmitTargetsCnt = 0;

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
  Future<void> addPullRequest(PullRequest pr) async {
    await super.addPullRequest(pr);
    addPullRequestCallCnt++;
  }
}

final emptyConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[
        pb.Target(name: 'Linux A', scheduler: pb.SchedulerSystem.luci),
      ],
    ),
  },
);

final exampleConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[
        pb.Target(name: 'Linux A', scheduler: pb.SchedulerSystem.luci),
        pb.Target(name: 'Mac A', scheduler: pb.SchedulerSystem.luci),
        pb.Target(name: 'Windows A', scheduler: pb.SchedulerSystem.luci),
        pb.Target(
          name: 'Google Internal Roll',
          presubmit: false,
          postsubmit: true,
          scheduler: pb.SchedulerSystem.google_internal,
        ),
      ],
    ),
  },
);

final exampleNaughtyConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[
        pb.Target(name: 'Windows A', scheduler: pb.SchedulerSystem.luci),
        pb.Target(name: 'Windows A', scheduler: pb.SchedulerSystem.luci),
      ],
    ),
  },
);

final exampleFlakyConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[
        pb.Target(
          name: 'Flaky 1',
          scheduler: pb.SchedulerSystem.luci,
          properties: {'flakiness_threshold': '0.04'},
        ),
        pb.Target(
          name: 'Flaky Skip',
          scheduler: pb.SchedulerSystem.luci,
          properties: {'ignore_flakiness': 'true'},
        ),
      ],
    ),
  },
);

final exampleBackfillConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
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
  },
);

final examplePresubmitRescheduleConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[
        pb.Target(name: 'Linux A'),
        pb.Target(
          name: 'Linux B',
          postsubmit: true,
          properties: {'presubmit_retry': '1'},
        ),
        pb.Target(
          name: 'Linux presubmit_max_attempts=2',
          properties: {'presubmit_max_attempts': '2'},
        ),
      ],
    ),
  },
);

final batchPolicyConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[
        pb.Target(name: 'Linux_android A'),
        pb.Target(name: 'Linux_android B'),
        pb.Target(name: 'Linux_android C'),
      ],
    ),
  },
);

final unsupportedPostsubmitCheckrunConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[pb.Target(name: 'Linux flutter')],
    ),
  },
);

final nonBringupPackagesConfig = CiYamlSet(
  slug: Config.packagesSlug,
  branch: Config.defaultBranch(Config.packagesSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.packagesSlug)],
      targets: <pb.Target>[pb.Target(name: 'Linux nonbringup')],
    ),
  },
);

final bringupPackagesConfig = CiYamlSet(
  slug: Config.packagesSlug,
  branch: Config.defaultBranch(Config.packagesSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.packagesSlug)],
      targets: <pb.Target>[pb.Target(name: 'Linux bringup', bringup: true)],
    ),
  },
);

final totCiYaml = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[
        pb.Target(name: 'Linux_android B'),
        pb.Target(name: 'Linux_android C'),
      ],
    ),
  },
);

final notInToTConfig = CiYamlSet(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  yamls: {
    CiType.any: pb.SchedulerConfig(
      enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
      targets: <pb.Target>[pb.Target(name: 'Linux_android A')],
    ),
  },
  totConfig: totCiYaml,
);
