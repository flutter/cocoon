// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

const String kTokenStorageKey = 'github-token';

String get token => window.localStorage[kTokenStorageKey];
set token(String value) => window.localStorage[kTokenStorageKey] = value;

bool get isSignedIn {
  return window.localStorage.containsKey(kTokenStorageKey);
}

void signOut() {
  window.localStorage.remove(kTokenStorageKey);
}
