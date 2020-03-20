// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Helper widget for easily switching between the normal widget and
/// CanvasKit specific widgets. Since CanvasKit is under active development,
/// the Flutter framework is not fully supported yet.
// Remove this workaround when the following issues have been removed:
// TODO(chillers): Show a Network Image. https://github.com/flutter/flutter/issues/45955
class CanvasKitWidget extends StatelessWidget {
  const CanvasKitWidget({
    Key key,
    this.canvaskit,
    this.other,
    bool useCanvasKit,
  })  : useCanvasKit = useCanvasKit ?? const bool.fromEnvironment('FLUTTER_WEB_USE_SKIA'),
        super(key: key);

  final bool useCanvasKit;

  final Widget canvaskit;

  final Widget other;

  @override
  Widget build(BuildContext context) => useCanvasKit ? canvaskit : other;
}
