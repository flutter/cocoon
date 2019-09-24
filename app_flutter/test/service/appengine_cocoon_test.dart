// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/appengine_cocoon.dart';
import 'package:cocoon_service/protos.dart';
import 'package:test/test.dart';

import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';

void main() {
  group('AppEngine CocoonService', () {
    test('should make an http request', () {
      final AppEngineCocoonService service = AppEngineCocoonService();
      service.client = MockClient((request) {
        const String jsonResponse = """
        {"Statuses": ["Checklist": {"Key": "iamatestkey", "Checklist": {"FlutterRepositoryPath": "flutter/cocoon", "CreateTimestamp": 123456789, "Commit": {"Sha": "ShaShankHash", "Author": {"Login": "iamacontributor", "avatar_url": "https://google.com"}}}}, "Stages": []], "AgentStatuses": []}
        """;

        return Future<Response>.delayed(
            Duration(microseconds: 500), () => Response(jsonResponse, 200));
      });

      expect(service.getStats(), TypeMatcher<Future<CommitStatus>>());
    });
  });
}
