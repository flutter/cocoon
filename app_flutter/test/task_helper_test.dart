// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon_service/protos.dart' show Commit, Task;

import 'package:app_flutter/task_helper.dart';

void main() {
  group('TaskHelper', () {
    test('log url for external tasks redirects to source configuration', () {
      final Task luciTask = Task()
        ..stageName = 'chromebot'
        ..name = 'mac_bot';

      expect(logUrl(luciTask, Commit()),
          'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/Mac');
      final Task cirrusTask = Task()..stageName = 'cirrus';

      expect(logUrl(cirrusTask, Commit()..sha = 'abc123'),
          'https://cirrus-ci.com/github/flutter/flutter/abc123');
    });

    test('log url for devicelab tasks redirects to cocoon backend', () {
      final Task devicelabTask = Task()
        ..stageName = 'devicelab'
        ..name = 'test';

      expect(logUrl(devicelabTask, Commit()),
          'https://flutter-dashboard.appspot.com/api/get-log?ownerKey=${devicelabTask.key}');
    });

    test('source configuration for devicelab', () {
      final Task devicelabTask = Task()
        ..stageName = 'devicelab'
        ..name = 'test';

      expect(sourceConfigurationUrl(devicelabTask),
          'https://github.com/flutter/flutter/blob/master/dev/devicelab/bin/tasks/test.dart');
    });

    test('source configuration for luci', () {
      final Task luciTask = Task()
        ..stageName = 'chromebot'
        ..name = 'mac_bot';

      expect(sourceConfigurationUrl(luciTask),
          'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/Mac');
    });
    test('source configuration for cirrus', () {
      final Task cirrusTask = Task()..stageName = 'cirrus';

      expect(sourceConfigurationUrl(cirrusTask),
          'https://cirrus-ci.com/github/flutter/flutter/master');
    });

    test('is devicelab', () {
      expect(isDevicelab(Task()..stageName = 'devicelab'), true);
      expect(isDevicelab(Task()..stageName = 'devicelab_win'), true);

      expect(isDevicelab(Task()..stageName = 'cirrus'), false);
    });
  });
}
