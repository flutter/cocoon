// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/google/grpc.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as push_message;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

void main() {
  ServiceAccountInfo serviceAccountInfo;
  FakeConfig config;
  FakeGithubService githubService;
  MockBuildBucketClient mockBuildBucketClient;
  LuciBuildService service;
  RepositorySlug slug;
  final MockGithubChecksUtil mockGithubChecksUtil = MockGithubChecksUtil();

  const List<LuciBuilder> builders = <LuciBuilder>[
    LuciBuilder(
      flaky: false,
      enabled: true,
      name: 'Linux',
      repo: 'flutter',
    ),
  ];

  group('getBuilds', () {
    const Build macBuild = Build(
      id: 999,
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'prod',
        builder: 'Mac',
      ),
      status: Status.started,
    );

    const Build linuxBuild = Build(
      id: 998,
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: 'Linux',
      ),
      status: Status.started,
    );

    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      githubService = FakeGithubService();
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo, githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      slug = RepositorySlug('flutter', 'cocoon');
    });
    test('Null build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[macBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<Build> builds = await service.getTryBuilds(
        slug,
        'commit123',
        'abcd',
      );
      expect(builds.first, macBuild);
    });
    test('Existing prod build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[],
              ),
            ),
          ],
        );
      });
      final Iterable<Build> builds = await service.getProdBuilds(
        slug,
        'commit123',
        'abcd',
        'flutter',
      );
      expect(builds, isEmpty);
    });
    test('Existing try build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<Build> builds = await service.getTryBuilds(
        slug,
        'commit123',
        'abcd',
      );
      expect(builds.first, linuxBuild);
    });
  });
  group('buildsForRepositoryAndPr', () {
    const Build macBuild = Build(
      id: 999,
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'prod',
        builder: 'Mac',
      ),
      status: Status.started,
    );

    const Build linuxBuild = Build(
      id: 998,
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'prod',
        builder: 'Linux',
      ),
      status: Status.started,
    );

    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      githubService = FakeGithubService();
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo, githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      slug = RepositorySlug('flutter', 'cocoon');
    });
    test('Empty responses are handled correctly', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[],
              ),
            ),
          ],
        );
      });
      final Map<String, Build> builds = await service.tryBuildsForRepositoryAndPr(slug, 1, 'abcd');
      expect(builds.keys, isEmpty);
    });

    test('Response returning a couple of builds', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[macBuild],
              ),
            ),
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final Map<String, Build> builds = await service.tryBuildsForRepositoryAndPr(slug, 1, 'abcd');
      expect(builds, equals(<String, Build>{'Mac': macBuild, 'Linux': linuxBuild}));
    });
  });
  group('scheduleBuilds', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      githubService = FakeGithubService();
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo, githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        serviceAccountInfo,
        githubChecksUtil: mockGithubChecksUtil,
      );
      service.setLogger(FakeLogging());
      slug = RepositorySlug('flutter', 'cocoon');
    });

    test('schedule try build set build url in check run', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              error: GrpcStatus(code: 0),
              scheduleBuild: Build(
                id: 998,
                builderId: BuilderId(
                  project: 'flutter',
                  bucket: 'prod',
                  builder: 'Linux',
                ),
                tags: <String, List<String>>{
                  'github_checkrun': <String>['1'],
                },
                status: Status.started,
              ),
            ),
          ],
        );
      });
      when(mockGithubChecksUtil.createCheckRun(any, config.flutterSlug, any, any)).thenAnswer((_) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2}
        });
      });
      final bool result = await service.scheduleTryBuilds(
        builders: builders,
        prNumber: 1,
        commitSha: 'abc',
        slug: config.flutterSlug,
      );
      expect(result, isTrue);
      verify(mockGithubChecksUtil.updateCheckRun(any, config.flutterSlug, any,
              detailsUrl: 'https://ci.chromium.org/ui/b/998'))
          .called(1);
    });
    test('try to schedule builds already started', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  Build(
                    id: 998,
                    builderId: BuilderId(
                      project: 'flutter',
                      bucket: 'prod',
                      builder: 'Linux',
                    ),
                    status: Status.started,
                  )
                ],
              ),
            ),
          ],
        );
      });
      final bool result = await service.scheduleTryBuilds(
        builders: builders,
        prNumber: 1,
        commitSha: 'abc',
        slug: slug,
      );
      expect(result, isFalse);
    });
    test('try to schedule builds already scheduled', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  Build(
                    id: 998,
                    builderId: BuilderId(
                      project: 'flutter',
                      bucket: 'prod',
                      builder: 'Linux',
                    ),
                    status: Status.scheduled,
                  )
                ],
              ),
            ),
          ],
        );
      });
      final bool result = await service.scheduleTryBuilds(
        builders: builders,
        prNumber: 1,
        commitSha: 'abc',
        slug: slug,
      );
      expect(result, isFalse);
    });
    test('Schedule builds throws when current list of builds is empty', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2}
        });
      });
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      await expectLater(
          service.scheduleTryBuilds(
            builders: <LuciBuilder>[],
            prNumber: 1,
            commitSha: 'abc',
            slug: slug,
          ),
          throwsA(isA<InternalServerError>()));
    });
    test('Try to schedule build on a unsupported repo', () async {
      slug = RepositorySlug('flutter', 'notsupported');
      expect(
          () async => await service.scheduleTryBuilds(
                builders: builders,
                prNumber: 1,
                commitSha: 'abc',
                slug: slug,
              ),
          throwsA(const TypeMatcher<BadRequestException>()));
    });
  });

  group('cancelBuilds', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      slug = RepositorySlug('flutter', 'cocoon');
    });
    test('Cancel builds when build list is empty', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      await service.cancelBuilds(slug, 1, 'abc', 'new builds');
      verify(mockBuildBucketClient.batch(any)).called(1);
    });
    test('Cancel builds that are scheduled', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
                searchBuilds: SearchBuildsResponse(builds: <Build>[
              Build(
                id: 998,
                builderId: BuilderId(
                  project: 'flutter',
                  bucket: 'prod',
                  builder: 'Linux',
                ),
                status: Status.started,
              )
            ]))
          ],
        );
      });
      await service.cancelBuilds(slug, 1, 'abc', 'new builds');
      expect(verify(mockBuildBucketClient.batch(captureAny)).captured[1].requests[0].cancelBuild.toJson(),
          json.decode('{"id": "998", "summaryMarkdown": "new builds"}'));
    });
    test('Cancel builds from unsuported repo', () async {
      slug = RepositorySlug('flutter', 'notsupported');
      expect(
          () async => await service.cancelBuilds(
                slug,
                1,
                'abc',
                'new builds',
              ),
          throwsA(const TypeMatcher<BadRequestException>()));
    });
  });

  group('failedBuilds', () {
    setUp(() {
      githubService = FakeGithubService();
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo, githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      slug = RepositorySlug('flutter', 'flutter');
    });
    test('Failed builds from an empty list', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      final List<Build> result = await service.failedBuilds(slug, 1, 'abc', <LuciBuilder>[]);
      expect(result, isEmpty);
    });
    test('Failed builds from a list of builds with failures', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
                searchBuilds: SearchBuildsResponse(builds: <Build>[
              Build(
                id: 998,
                builderId: BuilderId(
                  project: 'flutter',
                  bucket: 'prod',
                  builder: 'Linux',
                ),
                status: Status.failure,
              )
            ]))
          ],
        );
      });
      final List<Build> result = await service
          .failedBuilds(slug, 1, 'abc', <LuciBuilder>[const LuciBuilder(name: 'Linux', flaky: false, repo: 'flutter')]);
      expect(result, hasLength(1));
    });
  });
  group('rescheduleBuild', () {
    push_message.BuildPushMessage buildPushMessage;

    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final Map<String, dynamic> json = jsonDecode(buildPushMessageString(
        'COMPLETED',
        result: 'FAILURE',
        builderName: 'Linux Host Engine',
      )) as Map<String, dynamic>;
      buildPushMessage = push_message.BuildPushMessage.fromJson(json);
    });
    test('Reschedule an existing build', () async {
      final bool rescheduled = await service.rescheduleBuild(
        commitSha: 'abc',
        builderName: 'mybuild',
        buildPushMessage: buildPushMessage,
      );
      expect(rescheduled, isTrue);
      verify(mockBuildBucketClient.scheduleBuild(any)).called(1);
    });
  });
  group('rescheduleProdBuild', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
    });
    test('Reschedule an existing build', () async {
      await service.rescheduleProdBuild(
        commitSha: 'abc',
        builderName: 'mybuild',
        branch: 'master',
        repo: 'flutter',
      );
      verify(mockBuildBucketClient.scheduleBuild(any)).called(1);
    });
  });

  group('checkRerunBuilder', () {
    Commit commit;
    Commit totCommit;
    DatastoreService datastore;
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      service.setLogger(FakeLogging());
      datastore = DatastoreService(config.db, 5);
      commit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/abc'), sha: 'abc', repository: 'flutter/flutter');
      totCommit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/def'), sha: 'def', repository: 'flutter/flutter');
    });

    test('Rerun a test failed flutter builder', () async {
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      const LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/master',
          status: Task.statusFailed,
          buildNumber: 1,
          builderName: 'Mac abc',
          summaryMarkdown: 'summary');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 0,
        repo: 'flutter',
        datastore: datastore,
      );
      expect(rerunFlag, true);
    });

    test('Rerun an infra failed flutter builder', () async {
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      const LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/master',
          status: Task.statusInfraFailure,
          buildNumber: 1,
          builderName: 'Mac abc',
          summaryMarkdown: 'summary');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 0,
        repo: 'flutter',
        datastore: datastore,
      );
      expect(rerunFlag, true);
    });

    test('Do not rerun a successful flutter builder', () async {
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      const LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/master',
          status: Task.statusSucceeded,
          buildNumber: 1,
          builderName: 'Mac abc');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 0,
        repo: 'flutter',
        datastore: datastore,
      );
      expect(rerunFlag, false);
    });

    test('Do not rerun a flutter builder exceeding retry limit', () async {
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      const LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/master',
          status: Task.statusInfraFailure,
          buildNumber: 1,
          builderName: 'Mac abc');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 1,
        repo: 'flutter',
        datastore: datastore,
      );
      expect(rerunFlag, false);
    });

    test('Do not rerun a flutter builder when not blocking the tree', () async {
      config.db.values[totCommit.key] = totCommit;
      config.db.values[commit.key] = commit;
      config.maxLuciTaskRetriesValue = 1;
      const LuciTask luciTask = LuciTask(
          commitSha: 'abc',
          ref: 'refs/heads/master',
          status: Task.statusInfraFailure,
          buildNumber: 1,
          builderName: 'Mac abc');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: commit,
        luciTask: luciTask,
        retries: 0,
        repo: 'flutter',
        datastore: datastore,
      );
      expect(rerunFlag, false);
    });
  });
}
