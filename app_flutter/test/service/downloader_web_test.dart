// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:app_flutter/service/downloader_web.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Web Downloader', () {
    final Downloader downloader = Downloader();

    test('null href throws assertion error', () async {
      expect(() => downloader.download(null, 'dash'), throwsA(isA<AssertionError>()));
    });

    test('null filename throws assertion error', () async {
      expect(() => downloader.download('https://flutter.dev', null), throwsA(isA<AssertionError>()));
    });
  });
}
