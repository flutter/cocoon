// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:test/test.dart';

void main() {
  test('CheckRunEvent', () {
    final object = CheckRunEvent(action: 'Amazing');
    expect(
      object.toString(),
      stringContainsInOrder([
        'CheckRunEvent',
        '"action": "Amazing"',
      ]),
    );
  });

  test('CheckRun', () {
    const object = CheckRun(conclusion: 'Amazing');
    expect(
      object.toString(),
      stringContainsInOrder([
        'CheckRun',
        '"conclusion": "Amazing"',
      ]),
    );
  });

  test('MergeGroupEvent', () {
    final object = MergeGroupEvent(
      mergeGroup: const MergeGroup(
        headSha: 'headSha',
        headRef: 'headRef',
        baseSha: 'baseSha',
        baseRef: 'baseRef',
        headCommit: HeadCommit(id: 'id', treeId: 'treeId', message: 'message'),
      ),
      action: 'Amazing',
    );
    expect(
      object.toString(),
      stringContainsInOrder([
        'MergeGroupEvent',
        '"action": "Amazing"',
        '"head_sha": "headSha"',
        '"tree_id": "treeId"',
      ]),
    );
  });
}
