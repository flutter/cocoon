// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as push_message;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

void main() {
  ServiceAccountInfo serviceAccountInfo;
  FakeConfig config;
  MockBuildBucketClient mockBuildBucketClient;
  LuciBuildService service;
  RepositorySlug slug;
  final MockGithubChecksUtil mockGithubChecksUtil = MockGithubChecksUtil();
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
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
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
      final Map<String, Build> builds = await service.buildsForRepositoryAndPr(slug, 1, 'abcd');
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
      final Map<String, Build> builds = await service.buildsForRepositoryAndPr(slug, 1, 'abcd');
      expect(builds, equals(<String, Build>{'Mac': macBuild, 'Linux': linuxBuild}));
    });
  });
  group('scheduleBuilds', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
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
      final bool result = await service.scheduleBuilds(
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
      final bool result = await service.scheduleBuilds(
        prNumber: 1,
        commitSha: 'abc',
        slug: slug,
      );
      expect(result, isFalse);
    });
    test('Schedule builds when the current list of builds is empty', () async {
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
      config.luciTryBuildersValue =
          (json.decode('[{"name": "Cocoon", "repo": "cocoon"}]') as List<dynamic>).cast<Map<String, dynamic>>();
      final bool result = await service.scheduleBuilds(
        prNumber: 1,
        commitSha: 'abc',
        slug: slug,
      );
      expect(result, isTrue);
    });
    test('Try to schedule build on a unsupported repo', () async {
      slug = RepositorySlug('flutter', 'notsupported');
      expect(
          () async => await service.scheduleBuilds(
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
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
      service = LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      slug = RepositorySlug('flutter', 'cocoon');
    });
    test('Failed builds from an empty list', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      config.luciTryBuildersValue = <Map<String, dynamic>>[];
      final List<Build> result = await service.failedBuilds(slug, 1, 'abc');
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
      config.luciTryBuildersValue =
          (json.decode('[{"name": "Linux", "repo": "flutter", "taskName": "linux_bot"}]') as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final List<Build> result = await service.failedBuilds(slug, 1, 'abc');
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
      config.luciTryInfraFailureRetriesValue = 3;
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
}
