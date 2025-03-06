// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:test/test.dart';

void main() {
  final expectedNames = <String>['change', 'revert'];

  test('Expected string value for enum is returned.', () {
    for (var prChangeType in PullRequestChangeType.values) {
      assert(expectedNames.contains(prChangeType.name));
    }
    expect(PullRequestChangeType.values.length, 2);
  });
}
