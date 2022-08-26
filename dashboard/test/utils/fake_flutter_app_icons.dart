// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter_app_icons/flutter_app_icons_platform_interface.dart';

class FakeFlutterAppIcons extends FlutterAppIconsPlatform {
  @override
  Future<String?> setIcon({
    required String icon,
    String oldIcon = '',
    String appleTouchIcon = '',
  }) async {
    return icon;
  }
}
