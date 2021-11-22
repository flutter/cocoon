// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/enums/engine_or_framework.dart';
import 'package:conductor_ui/logic/engine_or_framework.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Not capitalized', () {
    test('engine', () {
      expect(engineOrFrameworkStr(EngineOrFramework.engine), equals('engine'));
    });

    test('framework', () {
      expect(engineOrFrameworkStr(EngineOrFramework.framework), equals('framework'));
    });
  });

  group('Capitalized', () {
    test('Engine', () {
      expect(engineOrFrameworkStr(EngineOrFramework.engine, true), equals('Engine'));
    });

    test('Framework', () {
      expect(engineOrFrameworkStr(EngineOrFramework.framework, true), equals('Framework'));
    });
  });
}
