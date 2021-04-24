// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/logic/qualified_task.dart';
import 'package:app_flutter/service/appengine_cocoon.dart';
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/downloader.dart';
import 'package:cocoon_service/protos.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Client, Request, Response;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

import '../utils/appengine_cocoon_test_data.dart';

void main() {
  group('AppEngine CocoonService fetchCommitStatus', () {
    AppEngineCocoonService service;

    setUp(() async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response(jsonGetStatsResponse, 200);
      }));
    });

    test('should return CocoonResponse<List<CommitStatus>>', () {
      expect(service.fetchCommitStatuses(),
          const TypeMatcher<Future<CocoonResponse<List<CommitStatus>>>>());
    });

    test('should return expected List<CommitStatus>', () async {
      final CocoonResponse<List<CommitStatus>> statuses =
          await service.fetchCommitStatuses();

      final CommitStatus expectedStatus = CommitStatus()
        ..branch = 'master'
        ..commit = (Commit()
          ..timestamp = Int64(123456789)
          ..key = (RootKey()..child = (Key()..name = 'iamatestkey'))
          ..sha = 'ShaShankHash'
          ..author = 'ShaSha'
          ..authorAvatarUrl = 'https://flutter.dev'
          ..repository = 'flutter/cocoon'
          ..branch = 'master')
        ..stages.add(Stage()
          ..name = 'devicelab'
          ..taskStatus = 'Succeeded'
          ..tasks.add(Task()
            ..key = (RootKey()..child = (Key()..name = 'taskKey1'))
            ..createTimestamp = Int64(1569353940885)
            ..startTimestamp = Int64(1569354594672)
            ..endTimestamp = Int64(1569354700642)
            ..name = 'complex_layout_semantics_perf'
            ..attempts = 1
            ..isFlaky = false
            ..timeoutInMinutes = 0
            ..reason = ''
            ..requiredCapabilities.add('[linux/android]')
            ..reservedForAgentId = 'linux2'
            ..stageName = 'devicelab'
            ..status = 'Succeeded'));

      expect(statuses.data.length, 1);
      expect(statuses.data.first, expectedStatus);
    });

    /// This requires a separate test run on the web platform.
    test('should query correct endpoint whether web or mobile', () async {
      final Client mockClient = MockHttpClient();
      when(mockClient.get(any))
          .thenAnswer((_) => Future<Response>.value(Response('', 200)));
      service = AppEngineCocoonService(client: mockClient);

      await service.fetchCommitStatuses();

      if (kIsWeb) {
        verify(mockClient.get('/api/public/get-status?branch=master'));
      } else {
        verify(
            mockClient.get('$baseApiUrl/api/public/get-status?branch=master'));
      }
    });

    /// This requires a separate test run on the web platform.
    test('should query correct endpoint when given a specific branch',
        () async {
      final Client mockClient = MockHttpClient();
      when(mockClient.get(any))
          .thenAnswer((_) => Future<Response>.value(Response('', 200)));
      service = AppEngineCocoonService(client: mockClient);

      await service.fetchCommitStatuses(branch: 'stable');

      if (kIsWeb) {
        verify(mockClient.get('/api/public/get-status?branch=stable'));
      } else {
        verify(
            mockClient.get('$baseApiUrl/api/public/get-status?branch=stable'));
      }
    });

    test(
        'given last commit status should query correct endpoint whether web or mobile',
        () async {
      final Client mockClient = MockHttpClient();
      when(mockClient.get(any))
          .thenAnswer((_) => Future<Response>.value(Response('', 200)));
      service = AppEngineCocoonService(client: mockClient);

      final CommitStatus status = CommitStatus()
        ..commit = (Commit()
          ..key = (RootKey()..child = (Key()..name = 'iamatestkey')));
      await service.fetchCommitStatuses(lastCommitStatus: status);

      if (kIsWeb) {
        verify(mockClient.get(
            '/api/public/get-status?lastCommitKey=iamatestkey&branch=master'));
      } else {
        verify(mockClient.get(
            '$baseApiUrl/api/public/get-status?lastCommitKey=iamatestkey&branch=master'));
      }
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('', 404)));

      final CocoonResponse<List<CommitStatus>> response =
          await service.fetchCommitStatuses();
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('bad', 200)));

      final CocoonResponse<List<CommitStatus>> response =
          await service.fetchCommitStatuses();
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService fetchCommitStatus - luci', () {
    AppEngineCocoonService service;

    setUp(() async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response(luciJsonGetStatsResponse, 200);
      }));
    });

    test('should return expected List<CommitStatus> - luci', () async {
      final CocoonResponse<List<CommitStatus>> statuses =
          await service.fetchCommitStatuses();

      final CommitStatus expectedStatus = CommitStatus()
        ..branch = 'master'
        ..commit = (Commit()
          ..timestamp = Int64(123456789)
          ..key = (RootKey()..child = (Key()..name = 'iamatestkey'))
          ..sha = 'ShaShankHash'
          ..author = 'ShaSha'
          ..authorAvatarUrl = 'https://flutter.dev'
          ..repository = 'flutter/cocoon'
          ..branch = 'master')
        ..stages.add(Stage()
          ..name = 'chromebot'
          ..taskStatus = 'Succeeded'
          ..tasks.add(Task()
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
            ..buildNumberList = '123'
            ..builderName = 'Linux'
            ..luciBucket = 'luci.flutter.try'));

      expect(statuses.data.length, 1);
      expect(statuses.data.first, expectedStatus);
    });
  });

  group('AppEngine CocoonService fetchTreeBuildStatus', () {
    AppEngineCocoonService service;

    setUp(() async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response(jsonBuildStatusTrueResponse, 200);
      }));
    });

    test('should return CocoonResponse<bool>', () {
      expect(service.fetchTreeBuildStatus(),
          const TypeMatcher<Future<CocoonResponse<BuildStatusResponse>>>());
    });

    test('data should be true when given Succeeded', () async {
      final CocoonResponse<BuildStatusResponse> treeBuildStatus =
          await service.fetchTreeBuildStatus();

      expect(treeBuildStatus.data.buildStatus, EnumBuildStatus.success);
    });

    test('data should be false when given Failed', () async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response(jsonBuildStatusFalseResponse, 200);
      }));
      final CocoonResponse<BuildStatusResponse> treeBuildStatus =
          await service.fetchTreeBuildStatus();

      expect(treeBuildStatus.data.buildStatus, EnumBuildStatus.failure);
    });

    /// This requires a separate test run on the web platform.
    test('should query correct endpoint whether web or mobile', () async {
      final Client mockClient = MockHttpClient();
      when(mockClient.get(any))
          .thenAnswer((_) => Future<Response>.value(Response('', 200)));
      service = AppEngineCocoonService(client: mockClient);

      await service.fetchTreeBuildStatus();

      if (kIsWeb) {
        verify(mockClient.get('/api/public/build-status?branch=master'));
      } else {
        verify(mockClient
            .get('$baseApiUrl/api/public/build-status?branch=master'));
      }
    });

    /// This requires a separate test run on the web platform.
    test('should query correct endpoint when given a specific branch',
        () async {
      final Client mockClient = MockHttpClient();
      when(mockClient.get(any))
          .thenAnswer((_) => Future<Response>.value(Response('', 200)));
      service = AppEngineCocoonService(client: mockClient);

      await service.fetchTreeBuildStatus(branch: 'stable');

      if (kIsWeb) {
        verify(mockClient.get('/api/public/build-status?branch=stable'));
      } else {
        verify(mockClient
            .get('$baseApiUrl/api/public/build-status?branch=stable'));
      }
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('', 404)));

      final CocoonResponse<BuildStatusResponse> response =
          await service.fetchTreeBuildStatus();
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('bad', 200)));

      final CocoonResponse<BuildStatusResponse> response =
          await service.fetchTreeBuildStatus();
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService rerun task', () {
    AppEngineCocoonService service;
    Task task;

    setUp(() {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response('', 200);
      }));
      task = Task()
        ..key = RootKey()
        ..stageName = StageName.devicelab;
    });

    test('should return true if request succeeds', () async {
      expect(await service.rerunTask(task, 'fakeAccessToken'), true);
    });

    test('should return false if request failed', () async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response('', 500);
      }));
      expect(await service.rerunTask(task, 'fakeAccessToken'), false);
    });

    test('should return false if task key is null', () async {
      expect(service.rerunTask(task, null),
          throwsA(const TypeMatcher<AssertionError>()));
    });

    /// This requires a separate test run on the web platform.
    test('should query correct endpoint whether web or mobile', () async {
      final Client mockClient = MockHttpClient();
      when(mockClient.post(argThat(endsWith('/api/reset-devicelab-task')),
              headers: captureAnyNamed('headers'),
              body: captureAnyNamed('body')))
          .thenAnswer((_) => Future<Response>.value(Response('', 200)));
      service = AppEngineCocoonService(client: mockClient);

      await service.rerunTask(task, '');

      if (kIsWeb) {
        verify(mockClient.post(
          '/api/reset-devicelab-task',
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        ));
      } else {
        verify(mockClient.post(
          '$baseApiUrl/api/reset-devicelab-task',
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        ));
      }
    });
  });

  group('AppEngine CocoonService refresh github commits', () {
    AppEngineCocoonService service;

    setUp(() {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response('', 200);
      }));
    });

    test('should return true if request succeeds', () async {
      expect(await service.vacuumGitHubCommits('fakeIdToken'), true);
    });

    test('should return false if request failed', () async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response('', 500);
      }));
      expect(await service.vacuumGitHubCommits('fakeIdToken'), false);
    });
  });

  group('AppEngine CocoonService download log', () {
    AppEngineCocoonService service;

    setUp(() {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response('', 200);
      }));
    });

    test('should throw assertion error if task is null', () async {
      expect(service.downloadLog(null, 'abc123', 'shashank'),
          throwsA(const TypeMatcher<AssertionError>()));
    });

    test('should throw assertion error if id token is null', () async {
      expect(service.downloadLog(Task()..key = RootKey(), null, 'shashank'),
          throwsA(const TypeMatcher<AssertionError>()));
    });

    test('should send correct request to downloader service', () async {
      final Downloader mockDownloader = MockDownloader();
      when(mockDownloader.download(argThat(contains('/api/get-log?ownerKey')),
              'test_task_shashan_1.log',
              idToken: 'abc123'))
          .thenAnswer((_) => Future<bool>.value(true));
      service = AppEngineCocoonService(
          client: MockClient((Request request) async {
            return Response('', 200);
          }),
          downloader: mockDownloader);

      expect(
          await service.downloadLog(
              Task()
                ..name = 'test_task'
                ..attempts = 1,
              'abc123',
              'shashankabcdefghijklmno'),
          isTrue);
    });
  });

  group('AppEngine CocoonService fetchFlutterBranches', () {
    AppEngineCocoonService service;

    setUp(() async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response(jsonGetBranchesResponse, 200);
      }));
    });

    test('should return CocoonResponse<List<String>>', () {
      expect(service.fetchFlutterBranches(),
          const TypeMatcher<Future<CocoonResponse<List<String>>>>());
    });

    test('data should be expected list of branches', () async {
      final CocoonResponse<List<String>> branches =
          await service.fetchFlutterBranches();

      expect(branches.data, <String>[
        'master',
        'flutter-0.0-candidate.1',
      ]);
    });

    /// This requires a separate test run on the web platform.
    test('should query correct endpoint whether web or mobile', () async {
      final Client mockClient = MockHttpClient();
      when(mockClient.get(any))
          .thenAnswer((_) => Future<Response>.value(Response('', 200)));
      service = AppEngineCocoonService(client: mockClient);

      await service.fetchFlutterBranches();

      if (kIsWeb) {
        verify(mockClient.get('/api/public/get-branches'));
      } else {
        verify(mockClient.get('$baseApiUrl/api/public/get-branches'));
      }
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('', 404)));

      final CocoonResponse<List<String>> response =
          await service.fetchFlutterBranches();
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('bad', 200)));

      final CocoonResponse<List<String>> response =
          await service.fetchFlutterBranches();
      expect(response.error, isNotNull);
    });
  });

  group('AppEngine CocoonService apiEndpoint', () {
    AppEngineCocoonService service;

    setUp(() {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response('{"Token": "abc123"}', 200);
      }));
    });
    test('handles url suffix', () {
      expect(service.apiEndpoint('/test'), '$baseApiUrl/test');
    });

    test('single query parameter', () {
      expect(
          service.apiEndpoint('/test',
              queryParameters: <String, String>{'key': 'value'}),
          '$baseApiUrl/test?key=value');
    });

    test('multiple query parameters', () {
      expect(
          service.apiEndpoint('/test', queryParameters: <String, String>{
            'key': 'value',
            'another': 'test'
          }),
          '$baseApiUrl/test?key=value&another=test');
    });

    test('query parameter with null value', () {
      expect(
          service.apiEndpoint('/test',
              queryParameters: <String, String>{'key': null}),
          '$baseApiUrl/test?key');
    });
  });
}

class MockHttpClient extends Mock implements Client {}

class MockDownloader extends Mock implements Downloader {}
