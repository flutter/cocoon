// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:cocoon_service/src/service/buildbucket.dart';
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
                buildbucket: buildbucket,
                githubChecksUtil: githubChecksUtil,
              ),
        );

  final CiYaml _defaultConfig = emptyConfig;

  /// [CiYaml] value to be injected on [getCiYaml].
  CiYaml? ciYaml;

  @override
  Future<CiYaml> getCiYaml(Commit commit, {CiYaml? totCiYaml, RetryOptions? retryOptions}) async =>
      ciYaml ?? _defaultConfig;

  @override
  Future<Commit> generateTotCommit({required String branch, required RepositorySlug slug}) async {
    return generateCommit(1);
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
        bringup: false,
        name: 'Google Internal Roll',
        presubmit: false,
        postsubmit: true,
        scheduler: pb.SchedulerSystem.google_internal,
      ),
    ],
  ),
);

CiYaml batchPolicyConfig = CiYaml(
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
    ],
  ),
);
