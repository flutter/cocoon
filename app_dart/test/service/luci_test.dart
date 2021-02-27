// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/mocks.dart';

void main() {
  BranchLuciBuilder branchLuciBuilder1;
  BranchLuciBuilder branchLuciBuilder2;

  test('validates effectiveness of class BranchLuciBuilder as a map key', () async {
    branchLuciBuilder1 = const BranchLuciBuilder(
        luciBuilder: LuciBuilder(name: 'abc', repo: 'def', flaky: false, taskName: 'ghi'), branch: 'jkl');
    branchLuciBuilder2 = const BranchLuciBuilder(
        luciBuilder: LuciBuilder(name: 'abc', repo: 'def', flaky: false, taskName: 'ghi'), branch: 'jkl');
    final Map<BranchLuciBuilder, String> map = <BranchLuciBuilder, String>{};
    map[branchLuciBuilder1] = 'test1';
    map[branchLuciBuilder2] = 'test2';

    expect(map[branchLuciBuilder1], 'test2');
  });

  test('luci status matches expected cocoon status', () async {
    final FakeConfig config = FakeConfig(githubService: FakeGithubService());
    final FakeClientContext clientContext = FakeClientContext();
    final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
    final LuciService service =
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext);
    final List<Build> builds = List<Build>.generate(
      luciStatusToTaskStatus.keys.length,
      (int index) => Build(
        id: index,
        number: index,
        builderId: const BuilderId(
          project: 'flutter',
          bucket: 'prod',
          builder: 'Linux',
        ),
        status: luciStatusToTaskStatus.keys.toList()[index],
      ),
    );
    when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
      return BatchResponse(
        responses: <Response>[
          Response(
            searchBuilds: SearchBuildsResponse(builds: builds),
          ),
        ],
      );
    });

    final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTaskBranchMap =
        await service.getBranchRecentTasks(repo: 'flutter');
    // There's no branch logic so there is only one entry
    expect(luciTaskBranchMap.keys.length, 1);
    final Map<String, List<LuciTask>> luciTaskMap = luciTaskBranchMap.values.first;
    final List<LuciTask> luciTasks = luciTaskMap['unknown'];
    for (LuciTask luciTask in luciTasks) {
      // Get associated luci builder to verify status is mapped correctly
      final Build luciBuild = builds[luciTask.buildNumber];
      expect(luciTask.status, luciStatusToTaskStatus[luciBuild.status]);
    }
  });
  test('luci getBuildsForBuilders works correctly', () async {
    final FakeConfig config = FakeConfig(githubService: FakeGithubService());
    final FakeClientContext clientContext = FakeClientContext();
    final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
    final LuciService service =
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext);
    const LuciBuilder builder = LuciBuilder(name: 'Linux', repo: 'flutter', flaky: false);
    final List<Build> builds = List<Build>.generate(
      luciStatusToTaskStatus.keys.length,
      (int index) => Build(
        id: index,
        number: index,
        builderId: const BuilderId(
          project: 'flutter',
          bucket: 'prod',
          builder: 'Linux',
        ),
        status: luciStatusToTaskStatus.keys.toList()[index],
      ),
    );
    when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
      return BatchResponse(
        responses: <Response>[
          Response(
            searchBuilds: SearchBuildsResponse(builds: builds),
          ),
        ],
      );
    });
    final List<Build> resultBuilds = await service.getBuildsForBuilderList(<LuciBuilder>[builder], repo: 'flutter');
    expect(resultBuilds, builds);
  });

  test('luci getPartialBuildersList works correctly', () async {
    final FakeConfig config = FakeConfig(githubService: FakeGithubService());
    final FakeClientContext clientContext = FakeClientContext();
    final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
    final LuciService service =
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext);
    const List<LuciBuilder> builders = <LuciBuilder>[
      LuciBuilder(name: 'Linux1', repo: 'flutter', flaky: false),
      LuciBuilder(name: 'Linux2', repo: 'flutter', flaky: false),
      LuciBuilder(name: 'Linux3', repo: 'flutter', flaky: false),
      LuciBuilder(name: 'Linux4', repo: 'flutter', flaky: false),
      LuciBuilder(name: 'Linux5', repo: 'flutter', flaky: false),
    ];

    final List<List<LuciBuilder>> partialBuildersList = service.getPartialBuildersList(builders, 2);
    expect(partialBuildersList, <List<LuciBuilder>>[
      <LuciBuilder>[
        const LuciBuilder(name: 'Linux1', repo: 'flutter', flaky: false),
        const LuciBuilder(name: 'Linux2', repo: 'flutter', flaky: false)
      ],
      <LuciBuilder>[
        const LuciBuilder(name: 'Linux3', repo: 'flutter', flaky: false),
        const LuciBuilder(name: 'Linux4', repo: 'flutter', flaky: false)
      ],
      <LuciBuilder>[
        const LuciBuilder(name: 'Linux5', repo: 'flutter', flaky: false)
      ]
    ]);
  });
}
