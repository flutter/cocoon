// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('DefaultBackfillStrategy', () {
    test('ignores targets not suitable for backfilling', () {});
  });
}
