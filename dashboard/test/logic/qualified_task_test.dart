// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/model/task.pb.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QualifiedTask.sourceConfigurationUrl for luci', () {
    final luciTask =
        Task()
          ..stageName = 'chromebot'
          ..name = 'abc'
          ..builderName = 'def';

    expect(
      QualifiedTask.fromTask(luciTask).sourceConfigurationUrl,
      'https://ci.chromium.org/p/flutter/builders/luci.flutter.prod/def',
    );
  });

  test('QualifiedTask.sourceConfigurationUrl for google test', () {
    final googleTestTask = Task()..stageName = 'google_internal';

    expect(
      QualifiedTask.fromTask(googleTestTask).sourceConfigurationUrl,
      'https://flutter-rob.corp.google.com',
    );
  });

  test('QualifiedTask.sourceConfigurationUrl for dart-internal', () {
    final dartInternalTask = Task()..stageName = 'dart-internal';

    expect(
      QualifiedTask.fromTask(dartInternalTask).sourceConfigurationUrl,
      'https://ci.chromium.org/p/dart-internal/builders/luci.flutter.prod/',
    );
  });

  test('QualifiedTask.isLuci', () {
    expect(const QualifiedTask(stage: 'luci', task: 'abc').isLuci, true);
    expect(const QualifiedTask(stage: 'chromebot', task: 'abc').isLuci, true);
    expect(const QualifiedTask(stage: 'cocoon', task: 'abc').isLuci, true);
    expect(
      const QualifiedTask(stage: 'google_internal', task: 'abc').isLuci,
      false,
    );
  });
}
