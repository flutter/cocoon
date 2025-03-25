// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/google_auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:test/test.dart';

void main() {
  test('delegates withCreateClient (no baseClient)', () async {
    late final List<String> capturedScopes;
    late final http.Client? capturedBaseClient;
    final mockClient = http_testing.MockClient((_) async {
      throw UnimplementedError();
    });

    final provider = FakeGoogleAuthProvider.withCreateClient(({
      required scopes,
      http.Client? baseClient,
    }) {
      capturedScopes = scopes;
      capturedBaseClient = baseClient;
      return mockClient;
    });
    await expectLater(
      provider.createClient(scopes: ['foo']),
      completion(same(mockClient)),
    );
    expect(capturedScopes, ['foo']);
    expect(capturedBaseClient, isNull);
  });

  test('delegates withCreateClient (with baseClient)', () async {
    final capturedScopes = <String>[];
    late final http.Client? capturedBaseClient;
    final mockClient = http_testing.MockClient((_) async {
      throw UnimplementedError();
    });

    final provider = FakeGoogleAuthProvider.withCreateClient(({
      required scopes,
      http.Client? baseClient,
    }) {
      capturedScopes.addAll(scopes);
      capturedBaseClient = baseClient;
      return mockClient;
    });
    await expectLater(
      provider.createClient(scopes: ['foo'], baseClient: mockClient),
      completion(same(mockClient)),
    );
    expect(capturedScopes, ['foo']);
    expect(capturedBaseClient, same(mockClient));
  });

  test('delegates withFixedClient', () async {
    final mockClient = http_testing.MockClient((_) async {
      throw UnimplementedError();
    });

    final provider = FakeGoogleAuthProvider.withFixedClient(mockClient);
    await expectLater(
      provider.createClient(scopes: ['foo']),
      completion(same(mockClient)),
    );
  });
}
