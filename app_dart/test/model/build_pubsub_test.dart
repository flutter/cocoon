// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/luci/build_pubsub.dart';
import 'package:test/test.dart';

import 'build_pubsub_test_data.dart';

void main() {
  test('Executable is handled correctly', () {
    final Executable exe = Executable.fromJson(jsonDecode(exeJson));
    expect(exe.cipdVersion, 'refs/heads/main');
    expect(exe.cipdPackage, 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build');
    expect(exe.cmd, ['luciexe']);
  });

  test('Agent', () {
    final Agent agent = Agent.fromJson(jsonDecode(agentJson));
    expect(agent, isNotNull);

    expect(agent.input, isNotNull);
    expect(agent.input!.data, isNotNull);
    expect(agent.input!.data!.length, 4);
    expect(agent.input!.data!.entries.any((element) => element.key == 'bbagent_utility_packages'), isTrue);
    final InputDataRef inputDataRef =
        agent.input!.data!.entries.firstWhere((element) => element.key == 'bbagent_utility_packages').value;
    expect(inputDataRef.cipd!.server == 'chrome-infra-packages.appspot.com', isTrue);
    expect(inputDataRef.cipd!.specs!.length, 1);
    expect(inputDataRef.cipd!.specs![0].package == 'infra/tools/luci/cas/platform', isTrue);
    expect(inputDataRef.cipd!.specs![0].version == 'git_revision:fe9985447e6b95f4907774f05e9774f031700775', isTrue);

    expect(agent.source, isNotNull);
    expect(agent.source!.cipd, isNotNull);
    expect(agent.source!.cipd!.package, 'infra/tools/luci/bbagent/platform');
    expect(agent.source!.cipd!.version, 'latest');
    expect(agent.source!.cipd!.server, 'chrome-infra-packages.appspot.com');

    expect(agent.purposes, isNotNull);
    expect(
      agent.purposes!.entries
          .any((element) => element.key == 'bbagent_utility_packages' && element.value.name == 'purposeBbAgentUtility'),
      isTrue,
    );
    expect(
      agent.purposes!.entries
          .any((element) => element.key == 'kitchen-checkout' && element.value.name == 'purposeExePayload'),
      isTrue,
    );

    expect(jsonEncode(agent.toJson()) == stripJson(agentJson), isTrue);
  });

  test('BuildBucketV2', () {
    final BuildBucket buildBucket = BuildBucket.fromJson(jsonDecode(buildBucketV2Json));
    expect(buildBucket.requestedProperties!.isEmpty, isTrue);
    expect(buildBucket.hostname! == 'cr-buildbucket-dev.appspot.com', isTrue);
    expect(buildBucket.experimentReasons!.length, 14);
    expect(buildBucket.knownPublicGerritHosts!.length, 15);
    expect(buildBucket.buildNumber, isTrue);
    expect(buildBucket.agent, isNotNull);

    expect(jsonEncode(buildBucket.toJson()) == stripJson(buildBucketV2Json), isTrue);
  });

  test('Swarming', () {
    final Swarming swarming = Swarming.fromJson(jsonDecode(swarmingJson));
    expect(swarming, isNotNull);
    expect(swarming.hostname, 'chromium-swarm-dev.appspot.com');
    expect(swarming.taskId, '62f2e84ef8411d10');
    expect(swarming.taskServiceAccount, 'chromium-ci-builder-dev@chops-service-accounts.iam.gserviceaccount.com');
    expect(swarming.priority, 30);
    expect(swarming.taskDimensions!.length, 3);

    expect(
      swarming.taskDimensions!.any((element) => element.key == 'pool' && element.value == 'luci.chromium.ci'),
      isTrue,
    );
    expect(swarming.taskDimensions!.any((element) => element.key == 'os' && element.value == 'Mac-13'), isTrue);
    expect(swarming.taskDimensions!.any((element) => element.key == 'cpu' && element.value == 'arm64'), isTrue);

    expect(swarming.caches, isNotNull);
    expect(swarming.caches!.length, 4);
    expect(swarming.caches!.any((element) => element.name == 'git' && element.path == 'git'), isTrue);
    expect(swarming.caches!.any((element) => element.name == 'goma' && element.path == 'goma'), isTrue);
    expect(
      swarming.caches!.any(
        (element) =>
            element.name == 'vpython' && element.path == 'vpython' && element.envVar == 'VPYTHON_VIRTUALENV_ROOT',
      ),
      isTrue,
    );
    expect(
      swarming.caches!.any(
        (element) =>
            element.name == 'builder_1b2b6e615f25d48545b2db3de147e58b8bea002f690605063288929bc1781d28_v2' &&
            element.path == 'builder' &&
            element.waitForWarmCache == '240s',
      ),
      isTrue,
    );
    final String jsonString = jsonEncode(swarming.toJson());
    assert(jsonString == stripJson(swarmingJson));
  });

  test('BuildInfra', () {
    final BuildInfra buildInfra = BuildInfra.fromJson(jsonDecode(buildInfraJson));
    expect(buildInfra.buildBucket, isNotNull);
    expect(buildInfra.swarming, isNotNull);
    expect(buildInfra.bbAgent, isNotNull);
    expect(buildInfra.bbAgent!.payloadPath, 'kitchen-checkout');
    expect(buildInfra.bbAgent!.cacheDir, 'cache');
  });

  test('Build', () {
    final Build build = Build.fromJson(jsonDecode(buildJson));
    expect(build.id, '8777746000874744641');
    expect(build.builder!.bucket, 'ci');
    expect(build.builder!.builder, 'mac-arm-rel-dev');
    expect(build.builder!.project, 'chromium');
    expect(build.number, 4721);
    expect(build.createdBy, 'project:chromium');
    expect(build.createTime, DateTime.parse('2023-06-20T18:35:05.236457827Z'));
    expect(build.endTime, DateTime.parse('2023-06-20T18:35:07.294256Z'));
    expect(build.updateTime, DateTime.parse('2023-06-20T18:35:07.294256Z'));
    expect(build.status, Status.infraFailure);
    expect(build.input, isNotNull);

    expect(build.input!.gitilesCommit!.host, 'chromium.googlesource.com');
    expect(build.input!.gitilesCommit!.project, 'chromium/src');
    expect(build.input!.gitilesCommit!.ref, 'refs/heads/main');
    expect(build.input!.gitilesCommit!.hash, 'a18a5bda2ee726a4e9c7cae848e4e4c8437a5d0e');

    expect(build.output, isNotNull);

    expect(build.tags!.isNotEmpty, isTrue);
    expect(build.tags!.length, 4);

    expect(build.buildInfra, isNotNull);

    expect(
      build.tags!.entries.any((element) =>
          element.key == 'buildset' &&
          element.value.first ==
              'commit/gitiles/chromium.googlesource.com/chromium/src/+/a18a5bda2ee726a4e9c7cae848e4e4c8437a5d0e',),
      isTrue,
    );
    expect(
      build.tags!.entries
          .any((element) => element.key == 'scheduler_invocation_id' && element.value.first == '8943176062752149552'),
      isTrue,
    );
    expect(
      build.tags!.entries
          .any((element) => element.key == 'scheduler_job_id' && element.value.first == 'chromium/mac-arm-rel-dev'),
      isTrue,
    );
    expect(
      build.tags!.entries.any((element) => element.key == 'user_agent' && element.value.first == 'luci-scheduler-dev'),
      isTrue,
    );

    expect(build.exe, isNotNull);
    expect(build.exe!.cipdPackage, 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build');
    expect(build.exe!.cipdVersion, 'refs/heads/main');
    expect(build.exe!.cmd!.length, 1);

    expect(build.schedulingTimeout, '21600s');
    expect(build.executionTimeout, '10800s');
    expect(build.gracePeriod, '30s');
  });
}
