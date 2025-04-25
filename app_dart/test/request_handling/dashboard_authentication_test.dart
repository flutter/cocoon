// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/account.dart';
import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:cocoon_service/src/request_handling/dashboard_authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_http.dart';
// import '../src/service/fake_firebase_jwt_validator.dart';
import '../src/service/fake_firebase_jwt_validator.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  group('DashboardCronAuthentication', () {
    late DashboardCronAuthentication auth;
    late FakeClientContext clientContext;
    late FakeHttpRequest request;

    setUp(() {
      request = FakeHttpRequest();
      clientContext = FakeClientContext();
      auth = DashboardCronAuthentication(
        clientContextProvider: () => clientContext,
      );
    });

    test('succeeds for App Engine cronjobs', () async {
      request.headers.set('X-Appengine-Cron', 'true');
      final result = await auth.authenticate(request);
      expect(result.clientContext, same(clientContext));
    });

    test('throws for non App Engine cronjobs', () async {
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });
  });

  group('DashboardFirebaseAuthentication', () {
    late DashboardFirebaseAuthentication auth;
    late FakeFirestoreService firestore;
    late FakeClientContext clientContext;
    late FakeFirebaseJwtValidator validator;
    late FakeHttpRequest request;

    setUp(() {
      firestore = FakeFirestoreService();
      request = FakeHttpRequest();
      clientContext = FakeClientContext();
      validator = FakeFirebaseJwtValidator();
      auth = DashboardFirebaseAuthentication(
        config: FakeConfig(),
        clientContextProvider: () => clientContext,
        validator: validator,
        firestore: firestore,
      );
    });

    test('succeeds for firebase jwt for googler', () async {
      validator.jwts.add(
        TokenInfo(email: 'abc123@google.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      final result = await auth.authenticate(request);
      expect(result.email, 'abc123@google.com');
    });

    test('succeeds for firebase jwt with allowed non-googler', () async {
      firestore.putDocument(Account(email: 'abc123@gmail.com'));
      validator.jwts.add(
        TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      final result = await auth.authenticate(request);
      expect(result.email, 'abc123@gmail.com');
    });

    test('fails for firebase jwt with non-allowed non-googler', () async {
      validator.jwts.add(
        TokenInfo(email: 'abc123@gmail.com', issued: DateTime.now()),
      );
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    test('fails for non-firebase jwt', () {
      request.headers.set('X-Flutter-IdToken', 'trustmebro');
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });
  });
}
