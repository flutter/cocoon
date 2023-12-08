// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:triage_bot/utils.dart';

void main() {
  test('hex', () {
    expect(hex(-1), '-1');
    expect(hex(0), '00');
    expect(hex(1), '01');
    expect(hex(15), '0f');
    expect(hex(16), '10');
    expect(hex(256), '100');
  });

  test('s', () {
    expect(s(-1), 's');
    expect(s(0), 's');
    expect(s(1), '');
    expect(s(15), 's');
    expect(s(16), 's');
    expect(s(256), 's');
  });
}
