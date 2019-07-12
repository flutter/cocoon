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
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'linux2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win1',
                'IsHealthy': true,
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 11)).millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 11)).millisecondsSinceEpoch
              },
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
    });

    test('Unexpected fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        final Map<String, dynamic> mapJson = <String, dynamic>{'bogus': 'Failure'};
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
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'linux2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win1',
                'IsHealthy': true,
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 11)).millisecondsSinceEpoch
              },
              <String, dynamic>{
                'AgentID': 'win2',
                'IsHealthy': false,
                'HealthCheckTimestamp': DateTime.now().subtract(const Duration(minutes: 11)).millisecondsSinceEpoch
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
