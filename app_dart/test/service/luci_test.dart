// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/luci.dart';

import 'package:test/test.dart';

void main() {
  BranchLuciBuilder branchLuciBuilder1;
  BranchLuciBuilder branchLuciBuilder2;

  test('listCommits decodes all relevant fields of each commit', () async {
    branchLuciBuilder1 = const BranchLuciBuilder(luciBuilder: LuciBuilder(name: 'abc', repo: 'def', flaky: false, taskName: 'ghi'), branch: 'jkl');
    branchLuciBuilder2 = const BranchLuciBuilder(luciBuilder: LuciBuilder(name: 'abc', repo: 'def', flaky: false, taskName: 'ghi'), branch: 'jkl');
    final Map<BranchLuciBuilder, String> map = <BranchLuciBuilder, String>{};
    map[branchLuciBuilder1] = 'test1';
    map[branchLuciBuilder2] = 'test2';
    
    expect(map[branchLuciBuilder1], 'test2');
  });
}
