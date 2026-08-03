// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/account.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  test('getByEmail returns account when exists, null otherwise', () async {
    final account = Account(email: 'user@example.com');
    firestoreService.putDocument(account);

    final found = await Account.getByEmail(
      firestoreService,
      email: 'user@example.com',
    );
    expect(found, isNotNull);
    expect(found!.email, 'user@example.com');

    final notFound = await Account.getByEmail(
      firestoreService,
      email: 'missing@example.com',
    );
    expect(notFound, isNull);
  });
}
