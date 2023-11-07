// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Precaches the images in the `assets` folder. This method must be called
/// before pumping any widgets.
Future<void> precacheTaskIcons(WidgetTester tester) async {
  // Depending on how we're invoked, Platform.script.path will have extra parts
  // after app_flutter. Just trim them off.
  final List<String> pathParts = path.split(Platform.script.path);
  while (pathParts.last != 'dashboard') {
    pathParts.removeLast();
  }

  final String assetPath = path.joinAll(<String>[...pathParts, 'assets']);
  final List<String> assets =
      Directory(assetPath).listSync().map((FileSystemEntity entity) => path.basename(entity.path)).toList();
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() async {
    for (final String asset in assets) {
      final ImageProvider provider = ExactAssetImage(path.join('assets', asset));
      await provider.evict();
      await precacheImage(
        provider,
        tester.allElements.first,
      );
    }
  });
}
