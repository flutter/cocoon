// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/google_auth_provider.dart';
import 'package:http/http.dart' as http;

/// A fake [GoogleAuthProvider] that returns a canned client or exception.
final class FakeGoogleAuthProvider implements GoogleAuthProvider {
  /// Creates a [GoogleAuthProvider] that delegates [createClient].
  ///
  /// For a simpler implementation, see [withFixedClient].
  const FakeGoogleAuthProvider.withCreateClient(this._createClient);
  final http.Client Function({
    required List<String> scopes,
    http.Client? baseClient,
  })
  _createClient;

  /// Creates a [GoogleAuthProvider] that always returns [client].
  factory FakeGoogleAuthProvider.withFixedClient(http.Client client) {
    http.Client createClient({
      required List<String> scopes,
      http.Client? baseClient,
    }) => client;
    return FakeGoogleAuthProvider.withCreateClient(createClient);
  }

  @override
  Future<http.Client> createClient({
    required List<String> scopes,
    http.Client? baseClient,
  }) async {
    return _createClient(scopes: scopes, baseClient: baseClient);
  }
}
