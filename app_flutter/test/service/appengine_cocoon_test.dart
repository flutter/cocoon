// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/appengine_cocoon.dart';
import 'package:app_flutter/service/cocoon.dart';
import 'package:test/test.dart';

void main() {
  group('AppEngine CocoonService', () {
    test('should make an http request', () {
      final CocoonService service = AppEngineCocoonService();

      service.getStats();
    });
  });
}