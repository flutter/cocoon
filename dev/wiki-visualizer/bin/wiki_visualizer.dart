// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:wiki_visualizer/dot.dart';
import 'package:wiki_visualizer/wiki_page.dart';

void main(final List<String> arguments) {
  if (arguments.isEmpty) {
    print('Usage: dart run wiki_visualizer file1.md file2.md file3.md ...');
    print('Paths should be relative to the root of the wiki.');
    exit(1);
  }

  final Wiki wiki = Wiki('https://github.com/flutter/flutter/wiki/');
  arguments.forEach(wiki.pageForFilename);
  for (final WikiPage page in wiki.pages) {
    page.parse(wiki);
  }

  final WikiPage sidebar = wiki.pageForTitle('_Sidebar');
  final Set<WikiPage> accessibleContent = sidebar.findAllAccessible();

  print('strict digraph {');
  final StringBuffer attributes = StringBuffer();
  for (final WikiPage page in wiki.pages) {
    if (page.sources.isEmpty) {
      attributes.write(' [style=filled] [fillcolor="#FFCCCC"] [fontcolor=black]');
    } else if (!accessibleContent.contains(page)) {
      attributes.write(' [color="#FF0000"]');
    } else if (page.sources.contains(sidebar)) {
      attributes.write(' [style=filled] [fillcolor="#CCFFCC"] [fontcolor=black]');
    }
    if (!page.parsed) {
      attributes.write(' [fontcolor=silver]');
    }
    print('  ${dotIdentifier(page.title)}$attributes');
    for (final WikiPage target in page.targets) {
      print('  ${dotIdentifier(page.title)} -> ${dotIdentifier(target.title)}');
    }
    attributes.clear();
  }
  print('}');
}
