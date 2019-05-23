// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

class GithubAuthentication {
  const GithubAuthentication();

  static const String _tokenStorageKey = 'github-token';

  static String get token => window.localStorage[_tokenStorageKey];
  static set token(String value) => window.localStorage[_tokenStorageKey] = value;

  static bool get isSignedIntoGithub {
    return window.localStorage.containsKey(_tokenStorageKey);
  }

  static void signOut() {
    window.localStorage.remove(_tokenStorageKey);
  }
}
