// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Precaches the images in the `assets` folder. This method must be called
/// before pumping any widgets.
///
/// This calls `tester.pump()` once after precaching the images.
Future<void> precacheTaskIcons(WidgetTester tester) async {
  final List<String> assets = Directory(path.join(path.dirname(Platform.script.path), 'assets'))
      .listSync()
      .map((FileSystemEntity entity) => entity.path)
      .toList();
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() async {
    for (final String asset in assets) {
      final ImageProvider provider = ExactAssetImage(asset);
      provider.evict();
      await precacheImage(
        provider,
        tester.allElements.first,
      );
    }
  });
  await tester.pump();
}
