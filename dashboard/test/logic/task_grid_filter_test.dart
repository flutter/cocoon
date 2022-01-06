// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/logic/task_grid_filter.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  void testDefault(TaskGridFilter filter) {
    expect(filter.toMap(includeDefaults: false).length, 0);
    expect(filter.taskFilter, null);
    expect(filter.authorFilter, null);
    expect(filter.messageFilter, null);
    expect(filter.hashFilter, null);
    expect(filter.isDefault, true);
    expect(filter.commitFilterMode, CommitFilterMode.highlight);
    // These booleans need commit query parameters to be non-default before they return true
    expect(filter.isHighlightingCommits, false);
    expect(filter.isFilteringCommits, false);

    expect(filter.matchesTask(QualifiedTask.fromTask(Task())), true);
    expect(filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')), true);
    expect(filter.matchesTask(QualifiedTask.fromTask(Task()..stageName = 'foo')), true);
    expect(filter.matchesTask(QualifiedTask.fromTask(Task()..stageName = StageName.cirrus)), true);
    expect(filter.matchesTask(QualifiedTask.fromTask(Task()..stageName = StageName.luci)), true);

    expect(filter.matchesCommit(Commit()), true);
    expect(filter.matchesCommit(Commit()..author = 'joe'), true);
    expect(filter.matchesCommit(Commit()..sha = '0x45c3fd'), true);
    expect(filter.matchesCommit(Commit()..message = 'LGTM!'), true);
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

  test('map constructor refuses unrecognized values', () {
    expect(() => TaskGridFilter.fromMap(<String, String>{'foo': 'bar'}), throwsNoSuchMethodError);
  });

  test('map constructor result matches field setters', () {
    expect(TaskGridFilter.fromMap(<String, String>{}), TaskGridFilter());
    expect(TaskGridFilter.fromMap(<String, String>{'taskFilter': 'foo'}), TaskGridFilter()..taskFilter = RegExp('foo'));
    expect(TaskGridFilter.fromMap(<String, String>{'authorFilter': 'foo'}),
        TaskGridFilter()..authorFilter = RegExp('foo'));
    expect(TaskGridFilter.fromMap(<String, String>{'messageFilter': 'foo'}),
        TaskGridFilter()..messageFilter = RegExp('foo'));
    expect(TaskGridFilter.fromMap(<String, String>{'hashFilter': 'foo'}), TaskGridFilter()..hashFilter = RegExp('foo'));
  });

  test('cross check on inequality', () {
    final TaskGridFilter defaultFilter = TaskGridFilter();
    final List<TaskGridFilter> nonDefaultFilters = <TaskGridFilter>[
      TaskGridFilter()..taskFilter = RegExp('foo'),
      TaskGridFilter()..authorFilter = RegExp('foo'),
      TaskGridFilter()..messageFilter = RegExp('foo'),
      TaskGridFilter()..hashFilter = RegExp('foo'),
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

  test('matches author name simple substring', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'authorFilter': 'foo'}),
      TaskGridFilter()..authorFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(Commit()..author = 'foo'), true);
      expect(filter.matchesCommit(Commit()..author = 'blah foo blah'), true);
      expect(filter.matchesCommit(Commit()..author = 'fo'), false);
    }
  });

  test('matches author name regexp', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'authorFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..authorFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(Commit()..author = 'z bc'), true);
      expect(filter.matchesCommit(Commit()..author = 'z bc z'), false);
      expect(filter.matchesCommit(Commit()..author = 'z b c'), false);
      expect(filter.matchesCommit(Commit()..author = 'foo'), false);
    }
  });

  test('matches commit message simple substring', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'messageFilter': 'foo'}),
      TaskGridFilter()..messageFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(Commit()..message = 'foo'), true);
      expect(filter.matchesCommit(Commit()..message = 'blah foo blah'), true);
      expect(filter.matchesCommit(Commit()..message = 'fo'), false);
    }
  });

  test('matches commit message regexp', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'messageFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..messageFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(Commit()..message = 'z bc'), true);
      expect(filter.matchesCommit(Commit()..message = 'z bc z'), false);
      expect(filter.matchesCommit(Commit()..message = 'z b c'), false);
      expect(filter.matchesCommit(Commit()..message = 'foo'), false);
    }
  });

  test('matches commit sha simple substring', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'hashFilter': 'foo'}),
      TaskGridFilter()..hashFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(Commit()..sha = 'foo'), true);
      expect(filter.matchesCommit(Commit()..sha = 'blah foo blah'), true);
      expect(filter.matchesCommit(Commit()..sha = 'fo'), false);
    }
  });

  test('matches commit sha regexp', () {
    final List<TaskGridFilter> filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'hashFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..hashFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final TaskGridFilter filter in filters) {
      expect(filter.matchesCommit(Commit()..sha = 'z bc'), true);
      expect(filter.matchesCommit(Commit()..sha = 'z bc z'), false);
      expect(filter.matchesCommit(Commit()..sha = 'z b c'), false);
      expect(filter.matchesCommit(Commit()..sha = 'foo'), false);
    }
  });

  test('isHighlightingCommits requires a commit query', () {
    final TaskGridFilter filter = TaskGridFilter();
    filter.commitFilterMode = CommitFilterMode.highlight;
    expect(filter.isHighlightingCommits, false);

    filter.authorFilter = RegExp('foo');
    expect(filter.isHighlightingCommits, true);
    filter.authorFilter = null;
    expect(filter.isHighlightingCommits, false);

    filter.messageFilter = RegExp('foo');
    expect(filter.isHighlightingCommits, true);
    filter.messageFilter = null;
    expect(filter.isHighlightingCommits, false);

    filter.hashFilter = RegExp('foo');
    expect(filter.isHighlightingCommits, true);
    filter.hashFilter = null;
    expect(filter.isHighlightingCommits, false);

    filter.authorFilter = RegExp('foo');
    filter.messageFilter = RegExp('foo');
    filter.hashFilter = RegExp('foo');
    expect(filter.isHighlightingCommits, true);
    filter.authorFilter = null;
    expect(filter.isHighlightingCommits, true);
    filter.messageFilter = null;
    expect(filter.isHighlightingCommits, true);
    filter.hashFilter = null;
    expect(filter.isHighlightingCommits, false);
  });

  test('isFilteringCommits requires a commit query', () {
    final TaskGridFilter filter = TaskGridFilter();
    filter.commitFilterMode = CommitFilterMode.filter;
    expect(filter.isFilteringCommits, false);

    filter.authorFilter = RegExp('foo');
    expect(filter.isFilteringCommits, true);
    filter.authorFilter = null;
    expect(filter.isFilteringCommits, false);

    filter.messageFilter = RegExp('foo');
    expect(filter.isFilteringCommits, true);
    filter.messageFilter = null;
    expect(filter.isFilteringCommits, false);

    filter.hashFilter = RegExp('foo');
    expect(filter.isFilteringCommits, true);
    filter.hashFilter = null;
    expect(filter.isFilteringCommits, false);

    filter.authorFilter = RegExp('foo');
    filter.messageFilter = RegExp('foo');
    filter.hashFilter = RegExp('foo');
    expect(filter.isFilteringCommits, true);
    filter.authorFilter = null;
    expect(filter.isFilteringCommits, true);
    filter.messageFilter = null;
    expect(filter.isFilteringCommits, true);
    filter.hashFilter = null;
    expect(filter.isFilteringCommits, false);
  });
}
