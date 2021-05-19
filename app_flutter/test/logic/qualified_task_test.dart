// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/logic/qualified_task.dart';

import 'package:cocoon_service/protos.dart' show Commit, Task;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logUrl() for external tasks redirects to source configuration', () {
    final Task luciTask = Task()
      ..stageName = 'chromebot'
      ..name = 'abc'
      ..builderName = 'def';

    expect(logUrl(luciTask), 'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/def');
    final Task cirrusTask = Task()..stageName = 'cirrus';

    expect(
        logUrl(cirrusTask,
            commit: Commit()
              ..sha = 'abc123'
              ..branch = 'master'),
        'https://cirrus-ci.com/build/flutter/flutter/abc123?branch=master');

    expect(logUrl(cirrusTask), 'https://cirrus-ci.com/github/flutter/flutter/master');
  });

  test('QualifiedTask.sourceConfigurationUrl for luci', () {
    final Task luciTask = Task()
      ..stageName = 'chromebot'
      ..name = 'abc'
      ..builderName = 'def';

    expect(QualifiedTask.fromTask(luciTask).sourceConfigurationUrl,
        'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/def');
  });

  test('QualifiedTask.sourceConfigurationUrl for cirrus', () {
    final Task cirrusTask = Task()..stageName = 'cirrus';

    expect(QualifiedTask.fromTask(cirrusTask).sourceConfigurationUrl,
        'https://cirrus-ci.com/github/flutter/flutter/master');
  });

  test('QualifiedTask.isLuci', () {
    expect(const QualifiedTask(stage: 'luci', task: 'abc').isLuci, true);
    expect(const QualifiedTask(stage: 'chromebot', task: 'abc').isLuci, true);
    expect(const QualifiedTask(stage: 'cocoon', task: 'abc').isLuci, true);
    expect(const QualifiedTask(stage: 'cirrus', task: 'abc').isLuci, false);
  });
}
