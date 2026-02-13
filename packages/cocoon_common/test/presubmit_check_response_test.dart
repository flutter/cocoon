// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:test/test.dart';

void main() {
  group('PresubmitCheckResponse', () {
    test('toJson and fromJson handles buildNumber', () {
      final json = {
        'attempt_number': 1,
        'build_name': 'linux',
        'creation_time': 1000,
        'status': 'succeeded',
        'build_number': 456,
      };

      final response = PresubmitCheckResponse.fromJson(json);
      expect(response.buildNumber, 456);

      final backToJson = response.toJson();
      expect(backToJson['build_number'], 456);
    });

    test('toJson and fromJson handles null buildNumber', () {
      final json = {
        'attempt_number': 1,
        'build_name': 'linux',
        'creation_time': 1000,
        'status': 'succeeded',
      };

      final response = PresubmitCheckResponse.fromJson(json);
      expect(response.buildNumber, isNull);

      final backToJson = response.toJson();
      expect(backToJson.containsKey('build_number'), isFalse);
    });
  });
}
