// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'downloader_interface.dart' as i;

/// Mobile implementation of [Downloader]. Not implemented.
class Downloader implements i.Downloader {
  @override
  Future<bool> download(String href, String fileName, {String idToken}) async {
    return false;
  }
}
