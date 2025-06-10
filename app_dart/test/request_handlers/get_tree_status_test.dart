// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/tree_status_change.dart';
import 'package:cocoon_service/src/request_handlers/get_tree_status_changes.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late GetTreeStatus handler;

  setUp(() {
    firestore = FakeFirestoreService();
    tester = ApiRequestHandlerTester();
    handler = GetTreeStatus(
      config: FakeConfig(),
      authenticationProvider: FakeDashboardAuthentication(),
      firestore: firestore,
    );

    tester.request.uri = tester.request.uri.replace(
      queryParameters: {'repo': 'flutter'},
    );
  });

  test('requires "repo"', () async {
    tester.request.uri = tester.request.uri.replace(queryParameters: {});

    await expectLater(tester.get(handler), throwsA(isA<BadRequestException>()));
  });

  test('returns < 10 changes', () async {
    var date = DateTime.now();
    for (var i = 0; i < 5; i++) {
      date = date.subtract(const Duration(minutes: 1));
      await TreeStatusChange.create(
        firestore,
        createdOn: date,
        status: TreeStatus.success,
        authoredBy: 'joe@google.com',
        repository: RepositorySlug('flutter', 'flutter'),
      );
    }

    final response = await tester.get(handler);
    await expectLater(
      response.body.collectBytes(),
      completion(decodedAsJson(hasLength(5))),
    );
  });

  test('returns 10 of N changes', () async {
    var date = DateTime.now();
    for (var i = 0; i < 15; i++) {
      date = date.subtract(const Duration(minutes: 1));
      await TreeStatusChange.create(
        firestore,
        createdOn: date,
        status: TreeStatus.success,
        authoredBy: 'joe@google.com',
        repository: RepositorySlug('flutter', 'flutter'),
      );
    }

    final response = await tester.get(handler);
    await expectLater(
      response.body.collectBytes(),
      completion(decodedAsJson(hasLength(10))),
    );
  });
}
