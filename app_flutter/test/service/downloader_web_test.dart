// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/service/downloader_web.dart';

void main() {
  group('Web Downloader', () {
    final Downloader downloader = Downloader();

    test('stub', () async {
      downloader.download('https://flutter.dev', 'dash');

      expect(true, true);
    });
  });
}
