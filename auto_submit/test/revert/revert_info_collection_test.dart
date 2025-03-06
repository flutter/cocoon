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
    const expected = 'flutter/cocoon#3460';
    expect(
      revertInfoCollection!.extractOriginalPrLink(sampleRevertBody),
      expected,
    );
  });

  test('extract initiating author', () {
    const expected = 'yusuf-goog';
    expect(
      revertInfoCollection!.extractInitiatingAuthor(sampleRevertBody),
      expected,
    );
  });

  test('extract revert reason', () {
    const expected = 'comment was added by mistake.';
    expect(
      revertInfoCollection!.extractRevertReason(sampleRevertBody),
      expected,
    );
  });

  test('extract original pr author', () {
    const expected = 'ricardoamador';
    expect(
      revertInfoCollection!.extractOriginalPrAuthor(sampleRevertBody),
      expected,
    );
  });

  test('extract original pr reviewers', () {
    const expected = '{keyonghan}';
    expect(revertInfoCollection!.extractReviewers(sampleRevertBody), expected);
  });

  test('extract the original revert info', () {
    const expected =
        'A long winded description about this change is revolutionary.';
    final description = revertInfoCollection!.extractRevertBody(
      sampleRevertBody,
    );
    expect(description!.contains(expected), isTrue);
  });

  test('extract reason with link', () {
    const expected =
        'Broke engine post-submit, see https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8753367119442265873/+/u/test:_Android_Unit_Tests__API_28_/stdout.';
    final reasonForRevert = revertInfoCollection!.extractRevertReason(
      sampleRevertBodyWithTrailingLink,
    );
    expect(reasonForRevert, expected);
  });
}
