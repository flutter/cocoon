// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'cookie_interface.dart' as i;

/// Utility service for managing HTML cookies.
class Cookie implements i.Cookie {
  @override
  Future<void> set(String name, String value, {String options = ''}) async {
    // This line is dangerous as it fails silently. Be careful.
    html.document.cookie = '$name=$value;$options';

    // This wait is a work around as the above line is not synchronous.
    // The cookie needs to be set for the request to be authenticated.
    //
    // dart:html will say the cookie has been written, but the browser
    // is still writing it.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
