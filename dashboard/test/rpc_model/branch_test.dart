// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('implements == and hashCode', () {
    final stable1 = Branch(channel: 'stable', reference: '1234');
    final stable2 = Branch(channel: 'stable', reference: '5678');

    expect(stable1, stable1);
    expect(stable1, isNot(stable2));
  });

  test('encodes and decodes to JSON', () {
    final example = Branch(channel: 'stable', reference: '1234');

    expect(Branch.fromJson(example.toJson()), example);
  });
}
