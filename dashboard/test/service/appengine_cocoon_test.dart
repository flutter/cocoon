// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/model/branch.pb.dart';
import 'package:flutter_dashboard/model/build_status_response.pb.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/commit_firestore.pb.dart';
import 'package:flutter_dashboard/model/commit_status.pb.dart';
import 'package:flutter_dashboard/model/commit_tasks_status.pb.dart';
import 'package:flutter_dashboard/model/key.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/model/task_firestore.pb.dart';
import 'package:flutter_dashboard/service/appengine_cocoon.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Request, Response;
import 'package:http/testing.dart';

import '../utils/appengine_cocoon_test_data.dart';

void main() {
  group('AppEngine CocoonService fetchCommitStatus', () {
    late AppEngineCocoonService service;

    setUp(() async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(luciJsonGetStatsResponse, 200);
        }),
      );
    });

    test('should return CocoonResponse<List<CommitStatus>>', () {
      expect(
        service.fetchCommitStatuses(repo: 'flutter'),
        const TypeMatcher<Future<CocoonResponse<List<CommitStatus>>>>(),
      );
    });

    test('should return expected List<CommitStatus>', () async {
      final statuses = await service.fetchCommitStatuses(repo: 'flutter');

      final expectedStatus =
          CommitStatus()
            ..branch = 'master'
            ..commit =
                (Commit()
                  ..timestamp = Int64(123456789)
                  ..key = (RootKey()..child = (Key()..name = 'iamatestkey'))
                  ..sha = 'ShaShankHash'
                  ..author = 'ShaSha'
                  ..authorAvatarUrl = 'https://flutter.dev'
                  ..repository = 'flutter/cocoon'
                  ..branch = 'master')
            ..tasks.add(
              Task()
                ..key = (RootKey()..child = (Key()..name = 'taskKey1'))
                ..createTimestamp = Int64(1569353940885)
                ..startTimestamp = Int64(1569354594672)
                ..endTimestamp = Int64(1569354700642)
                ..name = 'linux'
                ..attempts = 1
                ..isFlaky = false
                ..timeoutInMinutes = 0
                ..reason = ''
                ..requiredCapabilities.add('[linux]')
                ..reservedForAgentId = ''
                ..stageName = 'chromebot'
                ..status = 'Succeeded'
                ..isTestFlaky = false
                ..buildNumberList = '123'
                ..builderName = 'Linux'
                ..luciBucket = 'luci.flutter.try',
            );

      expect(statuses.data!.length, 1);
      expect(statuses.data!.first, expectedStatus);
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('', 404)),
      );

      final response = await service.fetchCommitStatuses(repo: 'flutter');
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('bad', 200)),
      );

      final response = await service.fetchCommitStatuses(repo: 'flutter');
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService fetchCommitStatusFirestore', () {
    late AppEngineCocoonService service;

    setUp(() async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(luciJsonGetStatsResponseFirestore, 200);
        }),
      );
    });

    test('should return CocoonResponse<List<CommitStatus>>', () {
      expect(
        service.fetchCommitStatusesFirestore(repo: 'flutter'),
        const TypeMatcher<Future<CocoonResponse<List<CommitTasksStatus>>>>(),
      );
    });

    test('should return expected List<CommitTasksStatus>', () async {
      final statuses = await service.fetchCommitStatusesFirestore(
        repo: 'flutter',
      );

      final expectedStatus =
          CommitTasksStatus()
            ..branch = 'master'
            ..commit =
                (CommitDocument()
                  ..documentName = 'commit/document/name'
                  ..createTimestamp = Int64(123456789)
                  ..sha = 'ShaShankHash'
                  ..author = 'ShaSha'
                  ..avatar = 'https://flutter.dev'
                  ..repositoryPath = 'flutter/cocoon'
                  ..branch = 'master'
                  ..message = 'message')
            ..tasks.add(
              TaskDocument()
                ..documentName = 'task/document/name'
                ..createTimestamp = Int64(1569353940885)
                ..startTimestamp = Int64(1569354594672)
                ..endTimestamp = Int64(1569354700642)
                ..taskName = 'linux'
                ..attempts = 1
                ..bringup = false
                ..status = 'Succeeded'
                ..testFlaky = false
                ..buildNumber = 123
                ..buildList = '123'
                ..commitSha = 'testSha',
            );

      expect(statuses.data!.length, 1);
      expect(statuses.data!.first, expectedStatus);
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('', 404)),
      );

      final response = await service.fetchCommitStatusesFirestore(
        repo: 'flutter',
      );
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('bad', 200)),
      );

      final response = await service.fetchCommitStatusesFirestore(
        repo: 'flutter',
      );
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService fetchTreeBuildStatus', () {
    late AppEngineCocoonService service;

    setUp(() async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(jsonBuildStatusTrueResponse, 200);
        }),
      );
    });

    test('should return CocoonResponse<bool>', () {
      expect(
        service.fetchTreeBuildStatus(repo: 'flutter'),
        const TypeMatcher<Future<CocoonResponse<BuildStatusResponse>>>(),
      );
    });

    test('data should be true when given Succeeded', () async {
      final treeBuildStatus = await service.fetchTreeBuildStatus(
        repo: 'flutter',
      );

      expect(treeBuildStatus.data!.buildStatus, EnumBuildStatus.success);
    });

    test('data should be false when given Failed', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(jsonBuildStatusFalseResponse, 200);
        }),
      );
      final treeBuildStatus = await service.fetchTreeBuildStatus(
        repo: 'flutter',
      );

      expect(treeBuildStatus.data!.buildStatus, EnumBuildStatus.failure);
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('', 404)),
      );

      final response = await service.fetchTreeBuildStatus(repo: 'flutter');
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('bad', 200)),
      );

      final response = await service.fetchTreeBuildStatus(repo: 'flutter');
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService rerun task', () {
    late AppEngineCocoonService service;
    late Task task;

    setUp(() {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response('', 200);
        }),
      );
      task =
          Task()
            ..key = RootKey()
            ..stageName = StageName.luci;
    });

    test('should return true if request succeeds', () async {
      final response = await service.rerunTask(
        task,
        'fakeAccessToken',
        'flutter',
      );
      expect(response.error, isNull);
    });

    test('should set error in response if task key is null', () async {
      final response = await service.rerunTask(task, null, 'flutter');
      expect(
        response.error,
        allOf(<Matcher>[isNotNull, contains('Sign in to trigger reruns')]),
      );
    });

    test(
      'should set error in response if bad status code is returned',
      () async {
        service = AppEngineCocoonService(
          client: MockClient((Request request) async {
            return Response('internal server error', 500);
          }),
        );

        final response = await service.rerunTask(
          task,
          'fakeAccessToken',
          'flutter',
        );
        expect(
          response.error,
          allOf(<Matcher>[
            isNotNull,
            contains('HTTP Code: 500, internal server error'),
          ]),
        );
      },
    );
  });

  group('AppEngine CocoonService refresh github commits', () {
    late AppEngineCocoonService service;

    setUp(() {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response('', 200);
        }),
      );
    });

    test('should return true if request succeeds', () async {
      expect(await service.vacuumGitHubCommits('fakeIdToken'), true);
    });

    test('should return false if request failed', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response('', 500);
        }),
      );
      expect(await service.vacuumGitHubCommits('fakeIdToken'), false);
    });
  });

  group('AppEngine CocoonService fetchFlutterBranches', () {
    late AppEngineCocoonService service;

    setUp(() async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(jsonGetBranchesResponse, 200);
        }),
      );
    });

    test('should return CocoonResponse<List<Branch>>', () {
      expect(
        service.fetchFlutterBranches(),
        const TypeMatcher<Future<CocoonResponse<List<Branch>>>>(),
      );
    });

    test('data should be expected list of branches', () async {
      final branches = await service.fetchFlutterBranches();

      expect(branches.error, isNull);
      expect(branches.data!.length, 4);
      expect(
        branches.data,
        containsAll([
          Branch()
            ..branch = 'flutter-3.13-candidate.0'
            ..channel = 'stable',
          Branch()
            ..branch = 'flutter-3.14-candidate.0'
            ..channel = 'beta',
          Branch()
            ..branch = 'flutter-3.15-candidate.5'
            ..channel = 'dev',
          Branch()
            ..branch = 'master'
            ..channel = 'HEAD',
        ]),
      );
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('', 404)),
      );

      final response = await service.fetchFlutterBranches();
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('bad', 200)),
      );

      final response = await service.fetchFlutterBranches();
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService fetchRepos', () {
    late AppEngineCocoonService service;

    setUp(() async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(jsonGetReposResponse, 200);
        }),
      );
    });

    test('data should be expected list of branches', () async {
      final repos = await service.fetchRepos();

      expect(repos.data, <String>['flutter', 'cocoon', 'packages']);
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('', 404)),
      );

      final response = await service.fetchRepos();
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('bad', 200)),
      );

      final response = await service.fetchRepos();
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService apiEndpoint', () {
    final service = AppEngineCocoonService(
      client: MockClient((Request request) async {
        return Response('{"Token": "abc123"}', 200);
      }),
    );

    test('handles url suffix', () {
      expect(service.apiEndpoint('/test').toString(), '$baseApiUrl/test');
    });

    test('single query parameter', () {
      expect(
        service
            .apiEndpoint(
              '/test',
              queryParameters: <String, String>{'key': 'value'},
            )
            .toString(),
        '$baseApiUrl/test?key=value',
      );
    });

    test('multiple query parameters', () {
      expect(
        service
            .apiEndpoint(
              '/test',
              queryParameters: <String, String>{
                'key': 'value',
                'another': 'test',
              },
            )
            .toString(),
        '$baseApiUrl/test?key=value&another=test',
      );
    });

    test('query parameter with null value', () {
      expect(
        service
            .apiEndpoint(
              '/test',
              queryParameters: <String, String?>{'key': null},
            )
            .toString(),
        '$baseApiUrl/test?key',
      );
    });

    /// This test requires runs on different platforms.
    test('should query correct endpoint whether web or mobile', () {
      final uri =
          service
              .apiEndpoint(
                '/test',
                queryParameters: <String, String?>{'key': null},
              )
              .toString();
      if (kIsWeb) {
        expect(uri, '/test?key');
      } else {
        expect(uri, '$baseApiUrl/test?key');
      }
    });
  });
}
