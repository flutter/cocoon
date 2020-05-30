// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';

void main() {
  ServiceAccountInfo serviceAccountInfo;
  FakeConfig config;
  MockBuildBucketClient mockBuildBucketClient;
  group('buildsForRepositoryAndPr', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
    });
    test('emptyResponse', () async {
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
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final Map<String, Build> builders =
          await service.buildsForRepositoryAndPr('cocoon', 1, 'abcd');
      expect(builders.keys, isEmpty);
    });

    test('someBuilders', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  Build(
                    id: 999,
                    builderId: BuilderId(
                      project: 'flutter',
                      bucket: 'prod',
                      builder: 'Mac',
                    ),
                    status: Status.started,
                  )
                ],
              ),
            ),
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
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final Map<String, Build> builders =
          await service.buildsForRepositoryAndPr('cocoon', 1, 'abcd');
      expect(builders.keys.toList(), equals(<String>['Mac', 'Linux']));
    });
  });
  group('scheduleBuilds', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
    });
    test('alreadyStarted', () async {
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
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final bool result = await service.scheduleBuilds(
        prNumber: 1,
        commitSha: 'abc',
        repositoryName: 'cocoon',
      );
      expect(result, isFalse);
    });
    test('alreadyScheduled', () async {
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
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final bool result = await service.scheduleBuilds(
        prNumber: 1,
        commitSha: 'abc',
        repositoryName: 'cocoon',
      );
      expect(result, isFalse);
    });
    test('emptyListBuild', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      config.luciTryBuildersValue =
          (json.decode('[{"name": "Cocoon", "repo": "cocoon"}]')
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final bool result = await service.scheduleBuilds(
        prNumber: 1,
        commitSha: 'abc',
        repositoryName: 'cocoon',
      );
      expect(result, isTrue);
    });
    test('unsupportedRepo', () async {
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      expect(
          () async => await service.scheduleBuilds(
                prNumber: 1,
                commitSha: 'abc',
                repositoryName: 'notsupported',
              ),
          throwsA(const TypeMatcher<BadRequestException>()));
    });
  });

  group('cancelBuilds', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
    });
    test('emptyList', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      await service.cancelBuilds('cocoon', 1, 'abc', 'new builds');
      verify(mockBuildBucketClient.batch(any)).called(1);
    });
    test('withScheduledBuild', () async {
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
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      await service.cancelBuilds('cocoon', 1, 'abc', 'new builds');
      verify(mockBuildBucketClient.batch(any)).called(2);
    });
    test('unsupportedRepo', () async {
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      expect(
          () async => await service.cancelBuilds(
                'notsupported',
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
    });
    test('emptyList', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final List<Build> result = await service.failedBuilds('cocoon', 1, 'abc');
      expect(result, isEmpty);
    });
    test('withFailures', () async {
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
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final List<Build> result = await service.failedBuilds('cocoon', 1, 'abc');
      expect(result, hasLength(1));
    });
  });
  group('rescheduleBuild', () {
    setUp(() {
      serviceAccountInfo = const ServiceAccountInfo(email: 'abc@abcd.com');
      config = FakeConfig(deviceLabServiceAccountValue: serviceAccountInfo);
      mockBuildBucketClient = MockBuildBucketClient();
    });
    test('worksProperly', () async {
      config.luciTryInfraFailureRetriesValue = 3;
      final LuciBuildService service =
          LuciBuildService(config, mockBuildBucketClient, serviceAccountInfo);
      final Map<String, List<String>> tags = <String, List<String>>{
        'buildset': <String>['123'],
        'user_agent': <String>['cocoon'],
        'github_link': <String>['the_link']
      };
      final Build build = Build(
          id: 123,
          builderId: const BuilderId(),
          tags: tags,
          input: const Input());
      await service.rescheduleBuild(
          commitSha: 'abc', builderName: 'mybuild', build: build, retries: 1);
      verify(mockBuildBucketClient.scheduleBuild(any)).called(1);
    });
  });
}

// ignore: must_be_immutable
class MockBuildBucketClient extends Mock implements BuildBucketClient {}
