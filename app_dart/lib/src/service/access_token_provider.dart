// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../datastore/cocoon_config.dart';
import '../model/appengine/service_account_info.dart';

/// Function signature for a [TaskService] provider.
typedef AccessTokenServiceProvider = AccessTokenService Function(Config config);

/// A provider for Oauth2 tokens from Service Account JSON.
class AccessTokenService {
  /// Creates a new Access Token provider.
  const AccessTokenService(this.config) : assert(config != null);

  /// The Cocoon configuration.
  final Config config;

  /// Creates and returns a [AccessTokenService] using a [Config] object.
  static AccessTokenService defaultProvider(Config config) {
    return AccessTokenService(config);
  }

  /// Returns an OAuth 2.0 access token for the device lab service account.
  Future<AccessToken> createAccessToken({
    List<String> scopes = const <String>[
      'https://www.googleapis.com/auth/cloud-platform'
    ],
  }) async {
    final ServiceAccountInfo serviceAccount =
        await config.deviceLabServiceAccount;
    final http.Client httpClient = http.Client();
    try {
      final AccessCredentials credentials =
          await obtainAccessCredentialsViaServiceAccount(
        serviceAccount.asServiceAccountCredentials(),
        scopes,
        httpClient,
      );
      return credentials.accessToken;
    } finally {
      httpClient.close();
    }
  }
}
