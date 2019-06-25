// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

const String kPausedTabIndexStorageKey = 'paused-tab-index';

int get pausedTabIndex {
  final String storedValue = window.localStorage[kPausedTabIndexStorageKey];
  return storedValue == null ? null : int.tryParse(storedValue);
}

bool get isPaused {
  return window.localStorage.containsKey(kPausedTabIndexStorageKey);
}

void pause(int taxIndex) {
  window.localStorage[kPausedTabIndexStorageKey] = taxIndex.toString();
}

void play() {
  window.localStorage.remove(kPausedTabIndexStorageKey);
}
