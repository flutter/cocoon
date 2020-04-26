// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'downloader_interface.dart' as i;

/// Web implementation of [Downloader].
class Downloader implements i.Downloader {
  /// Download a file located at [href] under the name of [fileName].
  ///
  /// If [idToken] is given, it will write an HTML cookie at `X-Flutter-IdToken`
  /// that can be authenticated with the Cocoon backend.
  ///
  /// Steps to download a file on web in Flutter:
  /// 1. Ensure authentication is up to date (for Cocoon logs).
  /// 2. Create an anchor element with the url to fetch and the name of the file
  ///    it will be downloaded to.
  /// 3. Click the anchor element to trigger the browser to download the file.
  @override
  Future<bool> download(String href, String fileName, {String idToken}) async {
    assert(href != null);
    assert(fileName != null);

    if (idToken != null) {
      // This line is dangerous as it fails silently. Be careful.
      html.document.cookie = 'X-Flutter-IdToken=$idToken;path=/';

      // This wait is a work around as the above line is not synchronous.
      // The cookie needs to be set for the request to be authenticated.
      //
      // dart:html will say the cookie has been written, but the browser
      // is still writing it.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    html.AnchorElement()
      ..href = href
      ..setAttribute('download', fileName)
      ..click();

    return true;
  }
}
