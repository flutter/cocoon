// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:googleapis/oauth2/v2.dart';
import 'package:http/http.dart' as http;

/// Authenticate and authorize incoming requests.
///
/// Ensure that the incoming requests are from specified
/// set of service accounts.
Future<bool> authenticateRequest(HttpHeaders headers) async {
  final http.Client client = http.Client();
  final Oauth2Api oauth2api = Oauth2Api(client);
  final String? idToken = headers.value(HttpHeaders.authorizationHeader);
  if (idToken == null || !idToken.startsWith('Bearer ')) {
    return false;
  }
  final Tokeninfo info = await oauth2api.tokeninfo(
    idToken: idToken.substring('Bearer '.length),
  );
  if (info.expiresIn == null || info.expiresIn! < 1) {
    return false;
  }

  /// XXX: flutter-dashboard-dev@ below is only for
  /// testing on project flutter-dashboard-dev.
  /// We should really make this a configurable list,
  /// so that it changes based on which stage (prod, staging,
  /// etc.) we deploy to.
  final Set<String> allowedServiceAccounts = <String>{
    'flutter-devicelab@flutter-dashboard.iam.gserviceaccount.com',
    'flutter-dashboard@appspot.gserviceaccount.com',
    'flutter-dashboard-dev@appspot.gserviceaccount.com',
  };
  return allowedServiceAccounts.contains(info.email);
}
