// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/config.dart';
import 'package:test/test.dart';

void main() {
  group('Config', () {
    late Config config;

    setUp(() {
      config = Config();
    });

    test('Two repos with tree status', () {
      expect(Config.reposWithTreeStatus.first.fullName, 'flutter/engine');
      expect(Config.reposWithTreeStatus.last.fullName, 'flutter/flutter');
    });

    test('Get roller Accounts', () {
      Set<String> testRollerAccounts = const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot',
      };
      expect(config.rollerAccounts, testRollerAccounts);
    });
  });
}
