// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:test/test.dart';

void main() {
  test('is ordered in a rational way', () {
    expect(Severity.values, orderedEquals([...Severity.values]..sort()));
  });

  test('operator >', () {
    expect(Severity.warning, greaterThan(Severity.info));
  });

  test('operator >=', () {
    expect(Severity.warning, greaterThanOrEqualTo(Severity.info));
    expect(Severity.warning, greaterThanOrEqualTo(Severity.warning));
  });
  test('operator <', () {
    expect(Severity.info, lessThan(Severity.warning));
  });

  test('operator <=', () {
    expect(Severity.info, lessThanOrEqualTo(Severity.info));
    expect(Severity.info, lessThanOrEqualTo(Severity.warning));
  });
}
