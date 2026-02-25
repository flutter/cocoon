// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/build_log_url.dart';
import 'package:test/test.dart';

void main() {
  group('generateBuildLogUrl', () {
    test('generates luci prod url', () {
      expect(
        generateBuildLogUrl(buildName: 'Linux', buildNumber: 123),
        '$luciProdLogBase/prod/Linux/123',
      );
    });

    test('generates luci staging url', () {
      expect(
        generateBuildLogUrl(
          buildName: 'Linux',
          buildNumber: 123,
          isBringup: true,
        ),
        '$luciProdLogBase/staging/Linux/123',
      );
    });

    test('generates dart-internal url', () {
      expect(
        generateBuildLogUrl(
          buildName: 'Linux flutter_release_builder',
          buildNumber: 123,
        ),
        '$dartInternalLogBase/flutter/Linux%20flutter_release_builder/123',
      );
    });
  });
}
