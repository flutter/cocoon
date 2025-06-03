// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/tree_status_change.dart';
import 'package:cocoon_service/src/request_handlers/update_tree_status.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late UpdateTreeStatus handler;

  final fakeNow = DateTime.now().toUtc();

  setUp(() {
    firestore = FakeFirestoreService();
    tester = ApiRequestHandlerTester();
    handler = UpdateTreeStatus(
      config: FakeConfig(),
      authenticationProvider: FakeDashboardAuthentication(),
      firestore: firestore,
      now: () => fakeNow,
    );
  });

  test('requires a "passing" status', () async {
    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );

    expect(firestore, existsInStorage(TreeStatusChange.metadata, isEmpty));
  });

  test('a "passing" status must be a boolean', () async {
    tester.request.body = jsonEncode({'passing': 'not-a-boolean'});
    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );

    expect(firestore, existsInStorage(TreeStatusChange.metadata, isEmpty));
  });

  test('updates Firestore', () async {
    tester.request.body = jsonEncode({'passing': false});
    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(TreeStatusChange.metadata, [
        isTreeStatusChange
            .hasCreatedOn(fakeNow)
            .hasStatus(TreeStatus.failure)
            .hasAuthoredBy('fake@example.com'),
      ]),
    );
  });
}
