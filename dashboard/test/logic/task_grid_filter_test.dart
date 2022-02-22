// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/logic/task_grid_filter.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/commit_status.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  void testDefault(TaskGridFilter filter) {
    expect(filter.toMap(includeDefaults: false).length, 0);
    expect(filter.taskFilter, null);
    expect(filter.authorFilter, null);
    expect(filter.messageFilter, null);
    expect(filter.hashFilter, null);
    expect(filter.showLuci, true);

    expect(filter.matchesTask(QualifiedTask.fromTask(Task())), true);
    expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')), true);
    expect(filter.matchesTask(QualifiedTask.fromTask(Task()..stageName = 'foo')), true);
    expect(filter.matchesTask(QualifiedTask.fromTask(Task()..stageName = StageName.luci)), true);

    expect(filter.matchesCommit(CommitStatus()), true);
    expect(filter.matchesCommit(CommitStatus()..commit = Commit()), true);
    expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'joe')), true);
    expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = '0x45c3fd')), true);
    expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'LGTM!')), true);
  }

  test('default task grid filter', () {
    testDefault(TaskGridFilter());
  });

  test('default task grid filter from null map', () {
    testDefault(TaskGridFilter.fromMap(null));
  });

  test('default task grid filter from empty map', () {
    testDefault(TaskGridFilter.fromMap(<String, String>{}));
  });

  test('map constructor allows unused values', () {
    expect(TaskGridFilter.fromMap(<String, String>{'repo': 'flutter'}), TaskGridFilter());
  });

  test('map constructor result matches field setters', () {
    expect(TaskGridFilter.fromMap(<String, String>{}), TaskGridFilter());
    expect(TaskGridFilter.fromMap(<String, String>{'taskFilter': 'foo'}), TaskGridFilter()..taskFilter = RegExp('foo'));
    expect(TaskGridFilter.fromMap(<String, String>{'authorFilter': 'foo'}),
        TaskGridFilter()..authorFilter = RegExp('foo'));
    expect(TaskGridFilter.fromMap(<String, String>{'messageFilter': 'foo'}),
        TaskGridFilter()..messageFilter = RegExp('foo'));
    expect(TaskGridFilter.fromMap(<String, String>{'hashFilter': 'foo'}), TaskGridFilter()..hashFilter = RegExp('foo'));
    expect(TaskGridFilter.fromMap(<String, String>{'showLuci': 'false'}), TaskGridFilter()..showLuci = false);
  });

  test('cross check on inequality', () {
    final TaskGridFilter defaultFilter = TaskGridFilter();
    final List<TaskGridFilter> nonDefaultFilters = <TaskGridFilter>[
      TaskGridFilter()..taskFilter = RegExp('foo'),
      TaskGridFilter()..authorFilter = RegExp('foo'),
      TaskGridFilter()..messageFilter = RegExp('foo'),
      TaskGridFilter()..hashFilter = RegExp('foo'),
      TaskGridFilter()..showLuci = false,
    ];
    for (final TaskGridFilter filter in nonDefaultFilters) {
      expect(filter, isNot(equals(defaultFilter)));
      expect(defaultFilter, isNot(equals(filter)));
    }
    for (int i = 0; i < nonDefaultFilters.length; i++) {
      for (int j = 0; j < nonDefaultFilters.length; j++) {
        if (i == j) {
          expect(nonDefaultFilters[i], nonDefaultFilters[j]);
        } else {
          expect(nonDefaultFilters[i], isNot(equals(nonDefaultFilters[j])));
        }
      }
    }
  });

  test('matches task name simple substring', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'taskFilter': 'foo'}),
      TaskGridFilter()..taskFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')), true);
      expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'blah foo blah')), true);
      expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'fo')), false);
    }
  });

  test('matches task name regexp', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'taskFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..taskFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'z bc')), true);
      expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'z bc z')), false);
      expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'z b c')), false);
      expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')), false);
    }
  });

  void testStage(
      {required String stageName,
      String? fieldName,
      required TaskGridFilter trueFilter,
      required TaskGridFilter falseFilter}) {
    final TaskGridFilter trueFilterMap = TaskGridFilter.fromMap(<String?, String>{fieldName: 'true'});
    final TaskGridFilter falseFilterMap = TaskGridFilter.fromMap(<String?, String>{fieldName: 'false'});

    expect(trueFilter, trueFilterMap);
    expect(trueFilter, isNot(equals(falseFilterMap)));
    expect(trueFilter, isNot(equals(falseFilter)));
    expect(falseFilter, falseFilterMap);
    expect(falseFilter, isNot(equals(trueFilterMap)));
    expect(falseFilter, isNot(equals(trueFilter)));

    expect(trueFilter.matchesTask(QualifiedTask.fromTask(Task()..stageName = stageName)), true);
    expect(trueFilterMap.matchesTask(QualifiedTask.fromTask(Task()..stageName = stageName)), true);

    expect(falseFilter.matchesTask(QualifiedTask.fromTask(Task()..stageName = stageName)), false);
    expect(falseFilterMap.matchesTask(QualifiedTask.fromTask(Task()..stageName = stageName)), false);
  }

  test('matches Luci stage', () {
    testStage(
      stageName: StageName.luci,
      fieldName: 'showLuci',
      trueFilter: TaskGridFilter()..showLuci = true,
      falseFilter: TaskGridFilter()..showLuci = false,
    );
  });

  test('matches author name simple substring', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'authorFilter': 'foo'}),
      TaskGridFilter()..authorFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'foo')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'blah foo blah')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'fo')), false);
    }
  });

  test('matches author name regexp', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'authorFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..authorFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'z bc')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'z bc z')), false);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'z b c')), false);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..author = 'foo')), false);
    }
  });

  test('matches commit message simple substring', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'messageFilter': 'foo'}),
      TaskGridFilter()..messageFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'foo')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'blah foo blah')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'fo')), false);
    }
  });

  test('matches commit message regexp', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'messageFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..messageFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'z bc')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'z bc z')), false);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'z b c')), false);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..message = 'foo')), false);
    }
  });

  test('matches commit sha simple substring', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'hashFilter': 'foo'}),
      TaskGridFilter()..hashFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = 'foo')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = 'blah foo blah')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = 'fo')), false);
    }
  });

  test('matches commit sha regexp', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'hashFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..hashFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = 'z bc')), true);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = 'z bc z')), false);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = 'z b c')), false);
      expect(filter.matchesCommit(CommitStatus()..commit = (Commit()..sha = 'foo')), false);
    }
  });
}
