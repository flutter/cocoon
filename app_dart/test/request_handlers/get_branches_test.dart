// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/request_handlers/get_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('GetBranches', () {
    FakeConfig config;
    RequestHandlerTester tester;
    GetBranches handler;

    setUp(() {
      config = FakeConfig();
      tester = RequestHandlerTester();
      handler = GetBranches(
        config,
      );
    });

    test('returns branches matching regExps', () async {
      config.flutterBranchesValue = 'flutter-1.1-candidate.1,master';

      final Body body = await tester.get(handler);
      final Map<String, dynamic> result = await utf8.decoder
          .bind(body.serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      expect(result['Branches'], <String>['flutter-1.1-candidate.1', 'master']);
    });
  });
}
