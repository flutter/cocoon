// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon_service/protos.dart' show Task;

import 'package:app_flutter/task_helper.dart';

void main() {
  group('TaskHelper', () {
    test('source configuration for devicelab', () {
      final Task devicelabTask = Task()
        ..stageName = 'devicelab'
        ..name = 'test';

      expect(TaskHelper().sourceConfigurationUrl(devicelabTask),
          'https://github.com/flutter/flutter/blob/master/dev/devicelab/bin/tasks/test.dart');
    });

    test('source configuration for luci', () {
      final Task luciTask = Task()
        ..stageName = 'chromebot'
        ..name = 'mac_bot';

      expect(TaskHelper().sourceConfigurationUrl(luciTask),
          'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/Mac');
    });
    test('source configuration for cirrus', () {
      final Task cirrusTask = Task()..stageName = 'cirrus';

      expect(TaskHelper().sourceConfigurationUrl(cirrusTask),
          'https://cirrus-ci.com/github/flutter/flutter/master');
    });
  });
}
