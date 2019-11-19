// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'downloader_interface.dart' as i;

class Downloader implements i.Downloader {
  @override
  Future<bool> download(String href, String fileName, String idToken) async {
    assert(href != null);
    assert(fileName != null);

    if (idToken != null) {
      // This line is dangerous as it fails silently. Be careful.
      html.document.cookie = 'X-Flutter-IdToken=$idToken;path=/';
      // This wait is a hack as the above line is not synchronous. It takes time
      // to write the cookie back to the browser. This is required before making
      // the download request.

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    html.AnchorElement()
      ..href = href
      ..setAttribute('download', fileName)
      ..click();

    return true;
  }
}
