// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:wiki_visualizer/wiki_page.dart';

void main() {
  test('smoke test', () {
    final Wiki wiki = Wiki('https://example.com/');
    wiki.pageForFilename('a.md').parseFromString(wiki, '[[b]]');
    wiki.pageForFilename('b.md').parseFromString(wiki, '[[x|c]] [y](https://example.com/d)');
    expect(wiki.pageForTitle('A').targets, <WikiPage>{wiki.pageForTitle('B')});
    expect(wiki.pageForTitle('A').parsed, isTrue);
    expect(wiki.pageForTitle('B').targets, <WikiPage>{wiki.pageForTitle('C'), wiki.pageForTitle('D')});
    expect(wiki.pageForTitle('B').parsed, isTrue);
    expect(wiki.pageForTitle('C').targets, isEmpty);
    expect(wiki.pageForTitle('C').parsed, isFalse);
    expect(wiki.pageForTitle('D').targets, isEmpty);
    expect(wiki.pageForTitle('D').parsed, isFalse);
  });
}
