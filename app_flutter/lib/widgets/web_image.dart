// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Helper widget for easily switching between the normal widget and
/// CanvasKit specific widgets. Since CanvasKit is under active development,
/// the Flutter framework is not fully supported yet.
///
/// This also bypasses CachedNetworkImageProvider when testing is enabled,
/// because that widget relies on plugins and plugins aren't available in tests.
// Remove the skia part of this workaround when the following issues have been removed:
// TODO(chillers): Show a Network Image. https://github.com/flutter/flutter/issues/45955
class WebImage extends StatelessWidget {
  const WebImage({
    Key key,
    bool enabled,
    this.imageUrl,
    this.imageBuilder,
    this.placeholder,
    this.errorWidget,
  })  : _enabled = enabled,
        super(key: key);

  final bool _enabled;
  bool get enabled {
    // This being a getter is sketchy but it's ok because in any execution of this code,
    // the value returned from this getter cannot change.
    // If it was possible for this value to change over time then this would not be a
    // valid way to write a widget and we would instead have to use a StatefulWidget.
    if (_enabled != null) {
      return _enabled;
    }
    // We have to use Platform.environment, not bool.fromEnvironment, because when the code is
    // compiled, the environment does not contain the FLUTTER_TEST key, but when the code is
    // executed as a test, it does. We have to check kIsWeb because the Platform.environment
    // feature doesn't exist on Web.
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    // Unlike FLUTTER_TEST, the FLUTTER_WEB_USE_SKIA key is set during compilation.
    if (const bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false)) {
      return false;
    }
    return true;
  }

  final String imageUrl;
  final ImageWidgetBuilder imageBuilder;
  final PlaceholderWidgetBuilder placeholder;
  final LoadingErrorWidgetBuilder errorWidget;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder: imageBuilder,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }
    return placeholder(context, imageUrl);
  }
}
