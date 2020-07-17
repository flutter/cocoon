// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:cocoon/repository/models/status_page_status.dart';
import 'package:cocoon/repository/services/status_page_service.dart';

void main() {
  group('StatusPage status fetch', () {
    test('Successful fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        final Map<String, dynamic> mapJson = <String, dynamic>{
          'status': <String, dynamic>{'description': 'Failure', 'indicator': 'minor'}
        };
        return http.Response(json.encode(mapJson), 200);
      });
      final StatusPageStatus status = await fetchStatusPageStatus('https://www.google.com', client: client);

      expect(status.status, 'Failure');
      expect(status.indicator, 'minor');
    });

    test('Unexpected fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        final Map<String, dynamic> mapJson = <String, dynamic>{'bogus': 'Failure'};
        return http.Response(json.encode(mapJson), 200);
      });
      final StatusPageStatus status = await fetchStatusPageStatus('https://www.google.com', client: client);

      expect(status, isNull);
    });

    test('Failed fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        return http.Response(null, 404);
      });
      final StatusPageStatus status = await fetchStatusPageStatus('https://www.google.com', client: client);

      expect(status, isNull);
    });
  });
}
