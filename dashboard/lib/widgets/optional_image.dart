// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Helper widget for switching between a network image and a placeholder.
///
/// This bypasses network image provider when testing to not surface the
/// HTTP errors in tests by default.
class OptionalImage extends StatelessWidget {
  const OptionalImage({
    super.key,
    bool? enabled,
    this.imageUrl,
    this.placeholder,
    this.width = 50,
    this.height = 50,
  }) : _enabled = enabled;

  final bool? _enabled;
  bool? get enabled {
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
    return true;
  }

  /// The url to fetch the image from.
  final String? imageUrl;

  /// Widget to fall back to if environment does not support network images.
  final Widget? placeholder;

  /// Height of the image.
  final double width;

  /// Width of the image.
  final double height;

  @override
  Widget build(BuildContext context) {
    if (enabled!) {
      return Image.network(imageUrl!, width: width, height: height);
    }
    return placeholder!;
  }
}
