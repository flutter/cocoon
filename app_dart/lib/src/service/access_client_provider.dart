// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import '../model/appengine/service_account_info.dart';

class AccessClientProvider {
  /// Creates a new Access Client provider.
  const AccessClientProvider(this.serviceAccountInfo) : assert(serviceAccountInfo != null);

  final ServiceAccountInfo serviceAccountInfo;

  /// Returns an OAuth 2.0 authenticated access client for the device lab service account.
  Future<Client> createAccessClient({
    List<String> scopes = const <String>[
      'https://www.googleapis.com/auth/cloud-platform'
    ],
  }) async {
    return clientViaServiceAccount(
          serviceAccountInfo.asServiceAccountCredentials(), scopes);
  }
}

