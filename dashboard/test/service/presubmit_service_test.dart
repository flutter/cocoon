// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_dashboard/service/appengine_cocoon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Request, Response;
import 'package:http/testing.dart';

void main() {
  group('AppEngine CocoonService fetchPresubmitGuard', () {
    late AppEngineCocoonService service;

    test('should return expected PresubmitGuardResponse', () async {
      final guardData = {
        'pr_num': 123,
        'check_run_id': 456,
        'author': 'dash',
        'guard_status': 'In Progress',
        'stages': [
          {
            'name': 'fusion',
            'created_at': 123456789,
            'builds': {
              'test1': 'Succeeded',
            },
          },
        ],
      };

      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(jsonEncode(guardData), 200);
        }),
      );

      final response = await service.fetchPresubmitGuard(
        repo: 'flutter',
        sha: 'abc',
      );

      expect(response.error, isNull);
      expect(response.data!.prNum, 123);
      expect(response.data!.stages[0].name, 'fusion');
    });

    test('should have error if given non-200 response', () async {
      service = AppEngineCocoonService(
        client: MockClient((Request request) async => Response('', 404)),
      );

      final response = await service.fetchPresubmitGuard(
        repo: 'flutter',
        sha: 'abc',
      );
      expect(response.error, isNotNull);
      expect(response.statusCode, 404);
    });
  });

  group('AppEngine CocoonService fetchPresubmitCheckDetails', () {
    late AppEngineCocoonService service;

    test('should return expected List<PresubmitCheckResponse>', () async {
      final checkData = [
        {
          'attempt_number': 1,
          'build_name': 'test1',
          'creation_time': 123456789,
          'status': 'Succeeded',
          'summary': 'Passed',
        },
      ];

      service = AppEngineCocoonService(
        client: MockClient((Request request) async {
          return Response(jsonEncode(checkData), 200);
        }),
      );

      final response = await service.fetchPresubmitCheckDetails(
        checkRunId: 456,
        buildName: 'test1',
      );

      expect(response.error, isNull);
      expect(response.data!.length, 1);
      expect(response.data!.first.buildName, 'test1');
    });
  });
}
