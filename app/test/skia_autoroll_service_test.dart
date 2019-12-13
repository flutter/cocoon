// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:cocoon/repository/models/skia_autoroll.dart';
import 'package:cocoon/repository/services/skia_autoroll_service.dart';

void main() {
  group('Autoroll fetch', () {
    test('Successful fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        final Map<String, dynamic> mapJson = <String, dynamic>{
          'mode': <String, dynamic>{'mode': 'running'},
          'lastRoll': <String, dynamic>{'result': 'suceeded'},
        };
        return http.Response(json.encode(mapJson), 200);
      });
      final SkiaAutoRoll roll = await fetchSkiaAutoRollModeStatus(
          'https://www.google.com',
          client: client);

      expect(roll.mode, 'running');
      expect(roll.lastRollResult, 'suceeded');
    });

    test('Unexpected fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        final Map<String, dynamic> mapJson = <String, dynamic>{
          'bogus': 'Failure'
        };
        return http.Response(json.encode(mapJson), 200);
      });
      final SkiaAutoRoll roll = await fetchSkiaAutoRollModeStatus(
          'https://www.google.com',
          client: client);

      expect(roll, isNull);
    });

    test('Failed fetch', () async {
      final MockClient client = MockClient((http.Request request) async {
        return http.Response(null, 404);
      });
      final SkiaAutoRoll roll = await fetchSkiaAutoRollModeStatus(
          'https://www.google.com',
          client: client);

      expect(roll, isNull);
    });
  });
}
