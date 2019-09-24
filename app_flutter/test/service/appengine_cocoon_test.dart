// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/appengine_cocoon.dart';
import 'package:cocoon_service/protos.dart' show Commit, CommitStatus, Stage;
import 'package:test/test.dart';

import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  // This is based off data the Cocoon backend sends out from v1.
  // It doesn't map perfectly to the protos since the backend does
  // not use the protos yet.
  final String jsonGetStatsResponse = """
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
                        "Attempts": 1
                      }
                    }
                  ]
                }
              ]
            }
          ], 
          "AgentStatuses": []
        }
  """;

  group('AppEngine CocoonService', () {
    AppEngineCocoonService service;

    setUp(() async {
      service = AppEngineCocoonService();
      service.client = MockClient((request) {
        return Future<Response>.delayed(Duration(microseconds: 100),
            () => Response(jsonGetStatsResponse, 200));
      });
    });

    test('should return List<CommitStatus>', () {
      expect(service.getStats(), TypeMatcher<Future<List<CommitStatus>>>());
    });

    test('should return expected List<CommitStatus>', () async {
      List<CommitStatus> statuses = await service.getStats();

      CommitStatus expectedStatus = CommitStatus()
        ..commit = (Commit()
          ..timestamp = Int64() + 123456789
          ..sha = 'ShaShankHash'
          ..author = 'ShaSha'
          ..authorAvatarUrl = 'https://flutter.dev'
          ..repository = 'flutter/cocoon')
        ..stages.add(Stage());

      expect(statuses.length, 1);
      expect(statuses.elementAt(0), expectedStatus);
    });

    test('should throw exception if given non-200 response', () {
      service.client = MockClient((request) => Future<Response>.delayed(
          Duration(microseconds: 100), () => Response('', 404)));

      expect(service.getStats(), throwsException);
    });

    test('should throw exception if given bad response', () {
      service.client = MockClient((request) => Future<Response>.delayed(
          Duration(microseconds: 100), () => Response('bad', 200)));

      expect(service.getStats(), throwsException);
    });
  });
}
