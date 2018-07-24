// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:http/browser_client.dart' as browser_http;
import 'package:http/http.dart' as http;

class AuthenticationStatus {
  final bool isAuthenticated;
  final String loginUrl;
  final String logoutUrl;

  AuthenticationStatus(this.isAuthenticated, this.loginUrl, this.logoutUrl);
}

Future<AuthenticationStatus> getAuthenticationStatus(String returnPage) async {
  http.Client client = new browser_http.BrowserClient();
  final String url = '/api/get-authentication-status?return-page=${returnPage}';
  Map<String, dynamic> status = json.decode((await client.get(url)).body);

  return new AuthenticationStatus(
    status['Status'] == 'OK',
    status['LoginURL'],
    status['LogoutURL'],
  );
}

Future<http.Client> getAuthenticatedClientOrRedirectToSignIn(String returnPage) async {
  final AuthenticationStatus status = await getAuthenticationStatus(returnPage);

  if (status.isAuthenticated)
    return new browser_http.BrowserClient();

  document.body.append(new DivElement()
    ..text = 'You are not signed in, or signed in under an unauthorized account, '
        'and will be redirected to a Google sign in page.');

  window.open(status.loginUrl, '_self');
  return null;
}
