// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:localstorage/localstorage.dart';

const String _kTokenStorageKey = 'github-token';

final LocalStorage storage = new LocalStorage('github.json');

String get token => storage.getItem(_kTokenStorageKey);
set token(String value) => storage.setItem(_kTokenStorageKey, value);

bool get isSignedIn {
  return storage.getItem(_kTokenStorageKey) != null;
}

void signOut() {
  storage.deleteItem(_kTokenStorageKey);
}
