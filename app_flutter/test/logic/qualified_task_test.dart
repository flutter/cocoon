// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon_service/protos.dart' show Commit, Task;

import 'package:app_flutter/logic/qualified_task.dart';

void main() {
  test('logUrl() for external tasks redirects to source configuration', () {
    final Task luciTask = Task()
      ..stageName = 'chromebot'
      ..name = 'mac_bot';

    expect(logUrl(luciTask), 'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/Mac');
    final Task cirrusTask = Task()..stageName = 'cirrus';

    expect(logUrl(cirrusTask, commit: Commit()..sha = 'abc123'), 'https://cirrus-ci.com/build/flutter/flutter/abc123');

    expect(logUrl(cirrusTask), 'https://cirrus-ci.com/github/flutter/flutter/master');
  });

  test('logUrl() for devicelab tasks redirects to cocoon backend', () {
    final Task devicelabTask = Task()
      ..stageName = 'devicelab'
      ..name = 'test';

    expect(logUrl(devicelabTask), 'https://flutter-dashboard.appspot.com/api/get-log?ownerKey=${devicelabTask.key}');
  });

  test('QualifiedTask.sourceConfigurationUrl for devicelab', () {
    final Task devicelabTask = Task()
      ..stageName = 'devicelab'
      ..name = 'test';

    expect(QualifiedTask.fromTask(devicelabTask).sourceConfigurationUrl,
        'https://github.com/flutter/flutter/blob/master/dev/devicelab/bin/tasks/test.dart');
  });

  test('QualifiedTask.sourceConfigurationUrl for luci', () {
    final Task luciTask = Task()
      ..stageName = 'chromebot'
      ..name = 'mac_bot';

    expect(QualifiedTask.fromTask(luciTask).sourceConfigurationUrl,
        'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/Mac');
  });

  test('QualifiedTask.sourceConfigurationUrl for cirrus', () {
    final Task cirrusTask = Task()..stageName = 'cirrus';

    expect(QualifiedTask.fromTask(cirrusTask).sourceConfigurationUrl,
        'https://cirrus-ci.com/github/flutter/flutter/master');
  });

  test('QualifiedTask.isDevicelab', () {
    expect(const QualifiedTask('devicelab', 'abc').isDevicelab, true);
    expect(const QualifiedTask('devicelab_win', 'abc').isDevicelab, true);
    expect(const QualifiedTask('cirrus', 'abc').isDevicelab, false);
  });
}
