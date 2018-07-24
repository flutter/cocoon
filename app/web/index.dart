// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:cocoon/logging.dart';
import 'package:cocoon/http.dart';

Future<Null> main() async {
  hide('#benchmarks-link');
  hide('#logout-button');
  hide('.login-button');

  logger = new HtmlLogger();

  final AuthenticationStatus status = await getAuthenticationStatus('/');
  if (status.isAuthenticated) {
    show('#benchmarks-link');
    show('#logout-button');

    document.querySelector('#logout-button').on['click'].listen((_) {
      window.open(status.logoutUrl, '_self');
    });
  } else {
    show('.login-button');

    if (window.location.hash.contains('show-sign-in-banner')) {
      show('#sign-in-required-banner');
    }

    document.querySelectorAll('.login-button').forEach((loginButton) {
      loginButton.on['click'].listen((_) {
        window.open(status.loginUrl, '_self');
      });
    });
  }
}

void hide(String selector) {
  document.querySelectorAll(selector).forEach((Element element) {
    element.style.display = 'none';
  });
}

void show(String selector) {
  document.querySelectorAll(selector).forEach((Element element) {
    element.style.display = 'block';
  });
}

class HtmlLogger implements Logger {
  @override
  void info(String message) => window.console.log(message);

  @override
  void warning(String message) => window.console.warn(message);

  @override
  void error(String message) => window.console.error(message);
}
