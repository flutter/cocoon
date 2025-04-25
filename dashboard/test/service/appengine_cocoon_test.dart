// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dashboard/service/appengine_cocoon.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/widgets/task_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Request, Response;
import 'package:http/testing.dart';

import '../utils/appengine_cocoon_test_data.dart';
import '../utils/generate_task_for_tests.dart';

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

    test('should return expected List<CommitStatus>', () async {
      final statuses = await service.fetchCommitStatuses(repo: 'flutter');

      final expectedStatus = CommitStatus(
        commit: Commit(
          timestamp: 123456789,
          sha: 'ShaShankHash',
          author: CommitAuthor(
            login: 'ShaSha',
            avatarUrl: 'https://flutter.dev',
          ),
          repository: 'flutter/cocoon',
          branch: 'master',
          message: 'This is a commit message',
        ),
        tasks: [
          Task(
            createTimestamp: 1569353940885,
            startTimestamp: 1569354594672,
            endTimestamp: 1569354700642,
            attempts: 1,
            isBringup: false,
            isFlaky: false,
            status: TaskBox.statusSucceeded,
            buildNumberList: [123],
            builderName: 'Linux',
            lastAttemptFailed: false,
            currentBuildNumber: 123,
          ),
        ],
      );

      expect(statuses.error, isNull);
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

  group('AppEngine CocoonService fetchTreeBuildStatus', () {
    late AppEngineCocoonService service;

    setUp(() async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(jsonBuildStatusTrueResponse, 200);
        }),
      );
    });

    test('data should be true when given Succeeded', () async {
      final treeBuildStatus = await service.fetchTreeBuildStatus(
        repo: 'flutter',
      );

      expect(treeBuildStatus.data!.buildStatus, BuildStatus.success);
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

      expect(treeBuildStatus.data!.buildStatus, BuildStatus.failure);
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
      task = generateTaskForTest(status: TaskBox.statusFailed);
    });

    test('should return true if request succeeds', () async {
      final response = await service.rerunTask(
        taskName: task.builderName,
        idToken: 'fakeAccessToken',
        repo: 'flutter',
        commitSha: 'abc123',
        branch: 'master',
      );
      expect(response.error, isNull);
    });

    test('should set error in response if ID token is null', () async {
      final response = await service.rerunTask(
        taskName: task.builderName,
        idToken: null,
        repo: 'flutter',
        commitSha: 'abc123',
        branch: 'master',
      );
      expect(
        response.error,
        allOf(<Matcher>[isNotNull, contains('Sign in to trigger reruns')]),
      );
    });

    test('should treat rerunCommit as task=all', () async {
      service = AppEngineCocoonService(
        client: MockClient((request) async {
          return Response('${request.url.toString()}|${request.body}', 500);
        }),
      );

      final response = await service.rerunCommit(
        idToken: 'fakeAccessToken',
        repo: 'flutter',
        commitSha: 'abc123',
        branch: 'master',
      );
      expect(
        response.error,
        endsWith(
          'api/rerun-prod-task|{"branch":"master","repo":"flutter","commit":"abc123","task":"all"}',
        ),
      );
    });

    test('should include statuses with rerunCommit', () async {
      service = AppEngineCocoonService(
        client: MockClient((request) async {
          return Response('${request.url.toString()}|${request.body}', 500);
        }),
      );

      final response = await service.rerunCommit(
        idToken: 'fakeAccessToken',
        repo: 'flutter',
        commitSha: 'abc123',
        branch: 'master',
        include: ['Foolish', 'Dashing'],
      );
      expect(
        response.error,
        endsWith(
          'api/rerun-prod-task|{"branch":"master","repo":"flutter","commit":"abc123","task":"all","include":"Foolish,Dashing"}',
        ),
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
          taskName: task.builderName,
          idToken: 'fakeAccessToken',
          repo: 'flutter',
          commitSha: 'abc123',
          branch: 'master',
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
      await expectLater(
        service.vacuumGitHubCommits('fakeIdToken'),
        completion(
          isA<CocoonResponse<bool>>().having((r) => r.data, 'data', isTrue),
        ),
      );
    });

    test('should return false if request failed', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response('', 500);
        }),
      );
      await expectLater(
        service.vacuumGitHubCommits('fakeIdToken'),
        completion(
          isA<CocoonResponse<bool>>().having((r) => r.error, 'data', isNotNull),
        ),
      );
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

    test('data should be expected list of branches', () async {
      final branches = await service.fetchFlutterBranches();

      expect(branches.error, isNull);
      expect(
        branches.data,
        unorderedEquals([
          Branch(channel: 'stable', reference: 'flutter-3.13-candidate.0'),
          Branch(channel: 'beta', reference: 'flutter-3.14-candidate.0'),
          Branch(channel: 'dev', reference: 'flutter-3.15-candidate.5'),
          Branch(channel: 'master', reference: 'master'),
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
