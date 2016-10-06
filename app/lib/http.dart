// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular2/core.dart';
import 'package:http/browser_client.dart' as browser_http;
import 'package:http/http.dart' as http;

Future<http.Client> getAuthenticatedClientOrRedirectToSignIn() async {
  http.Client client = new browser_http.BrowserClient();
  Map<String, dynamic> status = JSON.decode((await client.get('/api/get-authentication-status')).body);

  document.querySelector('#logout-button').on['click'].listen((_) {
    window.open(status['LogoutURL'], '_self');
  });

  document.querySelector('#login-button').on['click'].listen((_) {
    window.open(status['LoginURL'], '_self');
  });

  if (status['Status'] == 'OK')
    return client;

  document.body.append(new DivElement()
    ..text = 'You are not signed in, or signed in under an unauthorized account. '
             'Use the buttons at the bottom of this page to sign in.');
  return null;
}
