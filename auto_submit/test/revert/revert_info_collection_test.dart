// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/revert/revert_info_collection.dart';
import 'package:test/test.dart';
import 'revert_support_data.dart';

void main() {
  RevertInfoCollection? revertInfoCollection;

  setUp(() {
    revertInfoCollection = RevertInfoCollection();
  });

  test('extract reverts link', () {
    const String expected = 'Reverts flutter/cocoon#3460';
    expect(revertInfoCollection!.extractOriginalPrLink(sampleRevertBody), expected);
  });

  test('extract initiating author', () {
    const String expected = 'yusuf-goog';
    expect(revertInfoCollection!.extractInitiatingAuthor(sampleRevertBody), expected);
  });

  test('extract revert reason', () {
    const String expected = 'comment was added by mistake.';
    expect(revertInfoCollection!.extractRevertReason(sampleRevertBody), expected);
  });

  test('extract original pr author', () {
    const String expected = 'ricardoamador';
    expect(revertInfoCollection!.extractOriginalPrAuthor(sampleRevertBody), expected);
  });

  test('extract original pr reviewers', () {
    const String expected = '{keyonghan}';
    expect(revertInfoCollection!.extractReviewers(sampleRevertBody), expected);
  });

  test('extract the original revert info', () {
    const String expected1 = 'This change reverts the following previous change';
    const String expected2 = 'Original Description: A long winded description about this change is revolutionary.';
    final String? description = revertInfoCollection!.extractRevertBody(sampleRevertBody);
    expect(description!.contains(expected1), isTrue);
    expect(description.contains(expected2), isTrue);
  });
}
