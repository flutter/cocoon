// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

const String _kTokenStorageKey = 'github-token';

String get token => window.localStorage[_kTokenStorageKey];
set token(String value) => window.localStorage[_kTokenStorageKey] = value;

bool get isSignedIn {
  return window.localStorage.containsKey(_kTokenStorageKey);
}

void signOut() {
  window.localStorage.remove(_kTokenStorageKey);
}
