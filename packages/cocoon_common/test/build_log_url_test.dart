// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/build_log_url.dart';
import 'package:test/test.dart';

void main() {
  group('generatePostSubmitBuildLogUrl', () {
    test('generates luci prod url', () {
      expect(
        generatePostSubmitBuildLogUrl(buildName: 'Linux', buildNumber: 123),
        '$luciProdLogBase/prod/Linux/123',
      );
    });

    test('generates luci staging url', () {
      expect(
        generatePostSubmitBuildLogUrl(
          buildName: 'Linux',
          buildNumber: 123,
          isBringup: true,
        ),
        '$luciProdLogBase/staging/Linux/123',
      );
    });

    test('generates dart-internal url', () {
      expect(
        generatePostSubmitBuildLogUrl(
          buildName: 'Linux flutter_release_builder',
          buildNumber: 123,
        ),
        '$dartInternalLogBase/flutter/Linux%20flutter_release_builder/123',
      );
    });
    test('generates dart-internal url with isBringup', () {
      expect(
        generatePostSubmitBuildLogUrl(
          buildName: 'Linux flutter_release_builder',
          buildNumber: 123,
          isBringup: true,
        ),
        '$dartInternalLogBase/flutter/Linux%20flutter_release_builder/123',
      );
    });
  });

  group('generatePreSubmitBuildLogUrl', () {
    test('generates luci try url', () {
      expect(
        generatePreSubmitBuildLogUrl(buildName: 'Linux', buildNumber: 123),
        '$luciProdLogBase/try/Linux/123',
      );
    });

    test('generates dart-internal url', () {
      expect(
        generatePreSubmitBuildLogUrl(
          buildName: 'Linux flutter_release_builder',
          buildNumber: 123,
        ),
        '$dartInternalLogBase/flutter/Linux%20flutter_release_builder/123',
      );
    });
  });
}
