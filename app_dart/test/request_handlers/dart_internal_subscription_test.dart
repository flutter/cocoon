// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';

void main() {
  late DartInternalSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late SubscriptionTester tester;

  setUp(() async {
    config = FakeConfig(maxLuciTaskRetriesValue: 3);
    handler = DartInternalSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(
      request: request,
    );
  });

  test('runs successfully', () async {
    final Body response = await tester.post(handler);

    expect(response, Body.empty);
  });
}
