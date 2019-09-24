// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/appengine_cocoon.dart';
import 'package:cocoon_service/protos.dart';
import 'package:test/test.dart';

import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';

void main() {
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
                    "Login": "iamacontributor", 
                    "avatar_url": "https://google.com"
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

    test('should return expected List<CommitStatus>', () {});

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
