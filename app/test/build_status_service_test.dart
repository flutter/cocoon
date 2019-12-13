// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon/repository/models/build_status.dart';
import 'package:cocoon/repository/services/build_status_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('Build status fetch', () {
    test('Successful fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        if (request.url.path == 'api/public/get-status') {
          final Map<String, dynamic> mapJson = <String, dynamic>{
            'AgentStatuses': <Map<String, dynamic>>[
              <String, dynamic>{
                'AgentID': 'linux1',
                'IsHealthy': true,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 1))
                    .millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'linux2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 1))
                    .millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win1',
                'IsHealthy': true,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 11))
                    .millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 11))
                    .millisecondsSinceEpoch
              },
            ],
            'Statuses': <Map<String, dynamic>>[
              <String, dynamic>{
                'Checklist': <String, dynamic>{
                  'Checklist': <String, dynamic>{
                    'Commit': <String, dynamic>{
                      'Sha': '1234567890',
                      'Author': <String, dynamic>{
                        'Login': 'smith',
                        'avatar_url': 'https://www.google.com'
                      }
                    },
                    'CreateTimestamp': DateTime.now().millisecondsSinceEpoch
                  }
                },
                'Stages': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'Tasks': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'Task': <String, dynamic>{
                          'Flaky': false,
                          'Status': 'Succeeded',
                          'Name': 'test1'
                        }
                      },
                      <String, dynamic>{
                        'Task': <String, dynamic>{
                          'Flaky': false,
                          'Status': 'Failed',
                          'Name': 'test2'
                        }
                      },
                      <String, dynamic>{
                        'Task': <String, dynamic>{
                          'Flaky': true,
                          'Status': 'Failed',
                          'Name': 'test3'
                        }
                      },
                      <String, dynamic>{
                        'Task': <String, dynamic>{
                          'Flaky': false,
                          'Status': 'In Progress',
                          'Name': 'test4'
                        }
                      },
                      <String, dynamic>{
                        'Task': <String, dynamic>{
                          'Flaky': false,
                          'Status': 'New',
                          'Name': 'test5'
                        }
                      },
                    ]
                  }
                ]
              }
            ]
          };
          return http.Response(json.encode(mapJson), 200);
        } else {
          final Map<String, dynamic> mapJson = <String, dynamic>{
            'AnticipatedBuildStatus': 'Succeeded'
          };
          return http.Response(json.encode(mapJson), 200);
        }
      });
      final BuildStatus status = await fetchBuildStatus(client: client);

      expect(status.failingAgents, <String>['linux2', 'win1', 'win2']);
      expect(status.anticipatedBuildStatus, 'Succeeded');

      final List<CommitTestResult> commitTestResults = status.commitTestResults;
      CommitTestResult commitTestResult1 = commitTestResults.first;
      expect(commitTestResult1.sha, '1234567890');
      expect(commitTestResult1.authorName, 'smith');
      expect(commitTestResult1.avatarImageURL, 'https://www.google.com');
      expect(commitTestResult1.createDateTime.runtimeType, DateTime);
      expect(commitTestResult1.inProgressTestCount, 2);
      expect(commitTestResult1.succeededTestCount, 1);
      expect(commitTestResult1.failedFlakyTestCount, 1);
      expect(commitTestResult1.failedTestCount, 1);
      expect(commitTestResult1.failingTests, ['test2']);
    });

    test('Unexpected fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        final Map<String, dynamic> mapJson = <String, dynamic>{
          'bogus': 'Failure'
        };
        return http.Response(json.encode(mapJson), 200);
      });
      final BuildStatus status = await fetchBuildStatus(client: client);

      expect(status, isNotNull);
      expect(status.failingAgents, isEmpty);
      expect(status.anticipatedBuildStatus, isNull);
    });

    test('Build fetch fails, get status succeeds', () async {
      final MockClient client = MockClient((http.Request request) async {
        if (request.url.path == 'api/public/get-status') {
          final Map<String, dynamic> mapJson = <String, dynamic>{
            'AgentStatuses': <Map<String, dynamic>>[
              <String, dynamic>{
                'AgentID': 'linux1',
                'IsHealthy': true,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 1))
                    .millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'linux2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 1))
                    .millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win1',
                'IsHealthy': true,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 11))
                    .millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now()
                    .subtract(const Duration(minutes: 11))
                    .millisecondsSinceEpoch
              },
            ]
          };
          return http.Response(json.encode(mapJson), 200);
        } else {
          return http.Response(null, 404);
        }
      });
      final BuildStatus status = await fetchBuildStatus(client: client);

      expect(status.failingAgents, <String>['linux2', 'win1', 'win2']);
      expect(status.anticipatedBuildStatus, isNull);
    });

    test('Build fetch succeeds, get status fails', () async {
      final MockClient client = MockClient((http.Request request) async {
        if (request.url.path == 'api/public/get-status') {
          return http.Response(null, 404);
        } else {
          final Map<String, dynamic> mapJson = <String, dynamic>{
            'AnticipatedBuildStatus': 'Succeeded'
          };
          return http.Response(json.encode(mapJson), 200);
        }
      });
      final BuildStatus status = await fetchBuildStatus(client: client);

      expect(status.failingAgents, const <String>[]);
      expect(status.anticipatedBuildStatus, 'Succeeded');
    });

    test('Failed fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        return http.Response(null, 404);
      });
      final BuildStatus status = await fetchBuildStatus(client: client);

      expect(status.failingAgents, const <String>[]);
      expect(status.anticipatedBuildStatus, isNull);
    });
  });
}
