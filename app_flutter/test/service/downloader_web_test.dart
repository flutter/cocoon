// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Client, Request, Response;
import 'package:http/testing.dart';

import 'package:cocoon_service/protos.dart' show Task;

import 'package:app_flutter/service/appengine_cocoon.dart';

void main() {
  group('download log', () {
    AppEngineCocoonService service;
    final Task devicelabTask = Task()..stageName = 'devicelab';

    Client mockClient;

    setUp(() {
      mockClient = MockClient((Request request) async {
        return Response('', 200);
      });
      service = AppEngineCocoonService(client: mockClient);
    });
  });
}
