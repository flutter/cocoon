// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/google/grpc.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/mocks.dart';

void main() {
  BranchLuciBuilder branchLuciBuilder1;
  BranchLuciBuilder branchLuciBuilder2;
  FakeLogging log;

  setUp(() {
    log = FakeLogging();
  });

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
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext, log: log);
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
            error: const GrpcStatus(code: 200, message: null, details: null)
          ),
        ],
      );
    });

    final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTaskBranchMap =
        await service.getBranchRecentTasks(builders: <LuciBuilder>[
      const LuciBuilder(name: 'Linux', repo: 'flutter', taskName: 'linux_bot', flaky: false),
    ]);
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
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext, log: log);
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
            error: const GrpcStatus(code: 200, message: null, details: null)
          ),
        ],
      );
    });
    final List<Build> resultBuilds = await service.getBuildsForBuilderList(<LuciBuilder>[builder], repo: 'flutter');
    expect(resultBuilds, builds);
  });

  test('log error when response fails', () async {
    final FakeConfig config = FakeConfig(githubService: FakeGithubService());
    final FakeClientContext clientContext = FakeClientContext();
    final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
    final LuciService service =
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext, log: log);
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
            error: const GrpcStatus(code: 400, message: 'test', details: 'test error'),
          ),
        ],
      );
    });
    await service.getBuildsForBuilderList(<LuciBuilder>[builder], repo: 'flutter');
    expect(log.records.length, 1);
    expect(log.records[0].level.name, 'Error');
    expect(log.records[0].message, 'Failed search request response: [Response #400: test, test error]');
  });

  test('luci getPartialBuildersList handles non-uniform batches', () async {
    final FakeConfig config = FakeConfig(githubService: FakeGithubService());
    final FakeClientContext clientContext = FakeClientContext();
    final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
    final LuciService service =
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext, log: log);
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
      <LuciBuilder>[const LuciBuilder(name: 'Linux5', repo: 'flutter', flaky: false)]
    ]);
  });

  test('prepare search requests', () async {
    final FakeConfig config = FakeConfig(githubService: FakeGithubService());
    final FakeClientContext clientContext = FakeClientContext();
    final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
    final LuciService service =
        LuciService(buildBucketClient: mockBuildBucketClient, config: config, clientContext: clientContext, log: log);
    final List<LuciBuilder> luciBuilders = <LuciBuilder>[
      const LuciBuilder(name: 'Linux', repo: 'flutter', taskName: 'linux_bot', flaky: false),
    ];

    final List<Request> searchRequests = service.prepareSearchRequests('flutter', true, luciBuilders);
    expect(searchRequests.length, 2);
    expect(searchRequests[0].searchBuilds.predicate.tags, <String, List<String>>{
      'scheduler_job_id': <String>['flutter/Linux']
    });
    expect(searchRequests[1].searchBuilds.predicate.tags, <String, List<String>>{
      'scheduler_job_id': <String>['flutter/prod-Linux']
    });
  });
}
