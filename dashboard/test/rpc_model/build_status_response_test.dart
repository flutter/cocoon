// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final success = BuildStatusResponse(
    buildStatus: BuildStatus.success,
    failingTasks: [],
  );
  final failure = BuildStatusResponse(
    buildStatus: BuildStatus.failure,
    failingTasks: ['failing_task'],
  );

  test('implements == and hashCode', () {
    expect(success, success);
    expect(failure, failure);
  });

  test('encodes and decodes to JSON', () {
    expect(BuildStatusResponse.fromJson(success.toJson()), success);
    expect(BuildStatusResponse.fromJson(failure.toJson()), failure);
  });
}
