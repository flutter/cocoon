// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:device_doctor/src/ios_device.dart';

class FakeIosDeviceDiscovery extends IosDeviceDiscovery {
  FakeIosDeviceDiscovery(String output) : super.testing(output);

  List<dynamic> _outputs;
  int _pos = 0;

  set outputs(List<dynamic> outputs) {
    _pos = 0;
    _outputs = outputs;
  }

  @override
  Future<String> deviceListOutput() async {
    _pos++;
    if (_outputs[_pos - 1] is String) {
      return _outputs[_pos - 1] as String;
    } else {
      throw _outputs[_pos - 1];
    }
  }
}
