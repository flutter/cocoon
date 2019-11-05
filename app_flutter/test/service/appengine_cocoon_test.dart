// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' show Request, Response;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, RootKey, Stage, Task;

import 'package:app_flutter/service/appengine_cocoon.dart';
import 'package:app_flutter/service/cocoon.dart';

// This is based off data the Cocoon backend sends out from v1.
// It doesn't map directly to protos since the backend does
// not use protos yet.
const String jsonGetStatsResponse = '''
      {
        "Statuses": [
          {
          "Checklist": {
            "Key": "iamatestkey", 
            "Checklist": {
              "FlutterRepositoryPath": "flutter/cocoon", 
              "CreateTimestamp": 123456789, 
              "Commit": {
                "Sha": "ShaShankHash", 
                "Author": {
                  "Login": "ShaSha", 
                  "avatar_url": "https://flutter.dev"
                  }
                }
              }
            }, 
            "Stages": [
              {
                "Name": "devicelab",
                "Status": "Succeeded",
                "Tasks": [
                  {
                    "Key": "taskKey1",
                    "Task": {
                      "Attempts": 1,
                      "CreateTimestamp": 1569353940885,
                      "EndTimestamp": 1569354700642,
                      "Flaky": false,
                      "Name": "complex_layout_semantics_perf",
                      "Reason": "",
                      "RequiredCapabilities": ["linux/android"],
                      "ReservedForAgentID": "linux2",
                      "StageName": "devicelab",
                      "StartTimestamp": 1569354594672,
                      "Status": "Succeeded",
                      "TimeoutInMinutes": 0
                    }
                  }
                ]
              }
            ]
          }
        ], 
        "AgentStatuses": []
      }
''';

const String jsonBuildStatusTrueResponse = '''
  {
    "AnticipatedBuildStatus": "Succeeded"
  }
''';

const String jsonBuildStatusFalseResponse = '''
  {
    "AnticipatedBuildStatus": "Failed"
  }
''';

void main() {
  group('AppEngine CocoonService fetchCommitStatus ', () {
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
        ..commit = (Commit()
          ..timestamp = Int64(123456789)
          ..sha = 'ShaShankHash'
          ..author = 'ShaSha'
          ..authorAvatarUrl = 'https://flutter.dev'
          ..repository = 'flutter/cocoon')
        ..stages.add(Stage()
          ..name = 'devicelab'
          ..taskStatus = 'Succeeded'
          ..tasks.add(Task()
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

  group('AppEngine CocoonService fetchTreeBuildStatus ', () {
    AppEngineCocoonService service;

    setUp(() async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response(jsonBuildStatusTrueResponse, 200);
      }));
    });

    test('should return CocoonResponse<bool>', () {
      expect(service.fetchTreeBuildStatus(),
          const TypeMatcher<Future<CocoonResponse<bool>>>());
    });

    test('data should be true when given Succeeded', () async {
      final CocoonResponse<bool> treeBuildStatus =
          await service.fetchTreeBuildStatus();

      expect(treeBuildStatus.data, true);
    });

    test('data should be false when given Failed', () async {
      service =
          AppEngineCocoonService(client: MockClient((Request request) async {
        return Response(jsonBuildStatusFalseResponse, 200);
      }));

      final CocoonResponse<bool> treeBuildStatus =
          await service.fetchTreeBuildStatus();

      expect(treeBuildStatus.data, false);
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('', 404)));

      final CocoonResponse<bool> response =
          await service.fetchTreeBuildStatus();
      expect(response.error, isNotNull);
    });

    test('should have error if given bad response', () async {
      service = AppEngineCocoonService(
          client: MockClient((Request request) async => Response('bad', 200)));

      final CocoonResponse<bool> response =
          await service.fetchTreeBuildStatus();
      expect(response.error, isNotNull);
    });

    group('AppEngine Cocoon Service rerun task', () {
      AppEngineCocoonService service;

      setUp(() {
        service =
            AppEngineCocoonService(client: MockClient((Request request) async {
          return Response('', 200);
        }));
      });

      test('should return true if request succeeds', () async {
        expect(
            await service.rerunTask(Task()..key = RootKey(), 'fakeAccessToken'),
            true);
      });

      test('should return false if request failed', () async {
        service =
            AppEngineCocoonService(client: MockClient((Request request) async {
          return Response('', 500);
        }));

        expect(
            await service.rerunTask(Task()..key = RootKey(), 'fakeAccessToken'),
            false);
      });

      test('should return false if task key is null', () async {
        expect(service.rerunTask(Task(), null),
            throwsA(const TypeMatcher<AssertionError>()));
      });
    });
  });
}
