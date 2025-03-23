// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis_auth/auth_io.dart' as g;
import 'package:http/http.dart' as http;

/// Creates and returns an [http.Client] for accessing Google APIs.
interface class GoogleAuthProvider {
  const GoogleAuthProvider();

  /// Creates an [http.Client] for accessing [scopes].
  ///
  /// If [baseClient] is not provided, a default [http.Client.new] is used.
  Future<http.Client> createClient({
    required List<String> scopes,
    http.Client? baseClient,
  }) {
    return g.clientViaApplicationDefaultCredentials(
      scopes: scopes,
      baseClient: baseClient,
    );
  }
}
