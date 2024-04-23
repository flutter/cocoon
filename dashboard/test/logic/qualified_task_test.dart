// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/model/task.pb.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QualifiedTask.sourceConfigurationUrl for luci', () {
    final Task luciTask = Task()
      ..stageName = 'chromebot'
      ..name = 'abc'
      ..builderName = 'def';

    expect(
      QualifiedTask.fromTask(luciTask).sourceConfigurationUrl,
      'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/def',
    );
  });

  test('QualifiedTask.sourceConfigurationUrl for dart-internal', () {
    final Task dartInternalTask = Task()..builderName = 'Linux engine_release_builder';

    expect(
      QualifiedTask.fromTask(dartInternalTask).sourceConfigurationUrl,
      'https://ci.chromium.org/p/dart-internal/builders/flutter/Linux engine_release_builder',
    );
  });

  test('QualifiedTask.isLuci', () {
    expect(const QualifiedTask(task: 'abc').isLuci, true);
    expect(const QualifiedTask(task: 'Linux engine_release_builder').isLuci, false);
  });

  test('QualifiedTask.isDartInternal', () {
    expect(const QualifiedTask(task: 'abc').isDartInternal, false);
    expect(const QualifiedTask(task: 'Linux engine_release_builder').isDartInternal, true);
  });

  test('QualifiedTask.isEqual', () {
    const QualifiedTask task1 = QualifiedTask(task: 'abc');
    const QualifiedTask task2 = QualifiedTask(task: 'abc');

    expect(task1, task2);
  });
}
