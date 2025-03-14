// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

void main() {
  // Listen, it's more work than you (currently) think to special case this
  // particular repo for not running "dart test" with the shell script and
  // Dart test runner that tests the flutter/cocoon repository, and if we
  // *were* to add any tests, then we'd forget to run them.
  //
  // Sorry.
  test('has a test so that "dart test" does not fail in this package', () {});
}
