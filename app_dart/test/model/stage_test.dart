// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:test/test.dart';

Stage buildStage({
  String name = 'stage',
  List<String> statuses = const <String>[Task.statusNew],
}) {
  Iterable<Task> tasks = statuses.map<Task>((String status) => Task(status: status));
  StageBuilder builder = StageBuilder()
    ..name = name
    ..commit = Commit()
    ..tasks.addAll(tasks);
  return builder.build();
}

void main() {
  group('Stage', () {
    test('ordering', () {
      List<Stage> stages = <Stage>[
        buildStage(name: 'devicelab'),
        buildStage(name: 'unknown'),
        buildStage(name: 'cirrus'),
      ];
      stages.sort();
      expect(stages.map<String>((Stage stage) => stage.name),
          <String>['cirrus', 'devicelab', 'unknown']);
    });

    test('isManagedByDeviceLab', () {
      expect(buildStage(name: 'cirrus').isManagedByDeviceLab, isFalse);
      expect(buildStage(name: 'devicelab').isManagedByDeviceLab, isTrue);
      expect(buildStage(name: 'unknown').isManagedByDeviceLab, isFalse);
    });

    test('taskStatus', () {
      expect(
        buildStage(statuses: <String>[
          Task.statusSucceeded,
        ]).taskStatus,
        Task.statusSucceeded,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusSucceeded,
          Task.statusSucceeded,
          Task.statusFailed,
        ]).taskStatus,
        Task.statusFailed,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusNew,
          Task.statusFailed,
          Task.statusNew,
        ]).taskStatus,
        Task.statusFailed,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusInProgress,
          Task.statusFailed,
          Task.statusInProgress,
        ]).taskStatus,
        Task.statusFailed,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusSucceeded,
          Task.statusFailed,
          Task.statusSucceeded,
        ]).taskStatus,
        Task.statusFailed,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusNew,
          Task.statusFailed,
          Task.statusInProgress,
          Task.statusSucceeded,
        ]).taskStatus,
        Task.statusFailed,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusNew,
          Task.statusInProgress,
          Task.statusNew,
        ]).taskStatus,
        Task.statusInProgress,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusNew,
          Task.statusSucceeded,
          Task.statusNew,
        ]).taskStatus,
        Task.statusInProgress,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusSucceeded,
          Task.statusSucceeded,
          Task.statusInProgress,
        ]).taskStatus,
        Task.statusInProgress,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusNew,
          Task.statusNew,
        ]).taskStatus,
        Task.statusNew,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusInProgress,
          Task.statusInProgress,
        ]).taskStatus,
        Task.statusInProgress,
      );
      expect(
        buildStage(statuses: <String>[
          Task.statusSucceeded,
          Task.statusSucceeded,
        ]).taskStatus,
        Task.statusSucceeded,
      );
    });
  });

  group('StatusBuilder', () {
    test('validates state of the stage', () {
      expect(() => StageBuilder().build(), throwsStateError);
      expect(() => (StageBuilder()..name = 'name').build(), throwsStateError);
      expect(() => (StageBuilder()..commit = Commit()).build(), throwsStateError);
      expect(() => (StageBuilder()..name = 'name'..commit = Commit()).build(), throwsStateError);
    });
  });
}
