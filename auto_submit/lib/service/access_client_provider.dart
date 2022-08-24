// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

class AccessClientProvider {
  /// Returns an OAuth 2.0 authenticated access client for the device lab service account.
  Future<Client> createAccessClient({
    List<String> scopes = const <String>['https://www.googleapis.com/auth/cloud-platform'],
  }) async {
    return clientViaApplicationDefaultCredentials(scopes: scopes);
  }
}
