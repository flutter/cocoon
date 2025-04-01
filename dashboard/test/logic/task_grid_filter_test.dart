// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/logic/task_grid_filter.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/src/rpc_model.dart';
import 'package:flutter_dashboard/widgets/task_box.dart';

import 'package:flutter_test/flutter_test.dart';

import '../utils/generate_task_for_tests.dart';

void main() {
  void testDefault(TaskGridFilter filter) {
    expect(filter.toMap(), isEmpty);
    expect(filter.taskFilter, null);
    expect(filter.authorFilter, null);
    expect(filter.messageFilter, null);
    expect(filter.hashFilter, null);
    expect(filter.showiOS, true);
    expect(filter.showBringup, false);

    expect(filter.matchesTask(QualifiedTask.fromTask(Task())), true);
    expect(
      filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')),
      true,
    );

    expect(
      filter.matchesCommit(CommitStatus(commit: Commit(), tasks: [])),
      true,
    );
    expect(
      filter.matchesCommit(
        CommitStatus(commit: Commit()..author = 'joe', tasks: []),
      ),
      true,
    );
    expect(
      filter.matchesCommit(
        CommitStatus(commit: Commit()..sha = '0x45c3fd', tasks: []),
      ),
      true,
    );
    expect(
      filter.matchesCommit(
        CommitStatus(commit: Commit()..message = 'LGTM!', tasks: []),
      ),
      true,
    );
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
    expect(
      TaskGridFilter.fromMap(<String, String>{'repo': 'flutter'}),
      TaskGridFilter(),
    );
  });

  test('map constructor result matches field setters', () {
    expect(TaskGridFilter.fromMap(<String, String>{}), TaskGridFilter());
    expect(
      TaskGridFilter.fromMap(<String, String>{'taskFilter': 'foo'}),
      TaskGridFilter()..taskFilter = RegExp('foo'),
    );
    expect(
      TaskGridFilter.fromMap(<String, String>{'authorFilter': 'foo'}),
      TaskGridFilter()..authorFilter = RegExp('foo'),
    );
    expect(
      TaskGridFilter.fromMap(<String, String>{'messageFilter': 'foo'}),
      TaskGridFilter()..messageFilter = RegExp('foo'),
    );
    expect(
      TaskGridFilter.fromMap(<String, String>{'hashFilter': 'foo'}),
      TaskGridFilter()..hashFilter = RegExp('foo'),
    );
    expect(
      TaskGridFilter.fromMap(<String, String>{'showMac': 'false'}),
      TaskGridFilter()..showMac = false,
    );
    expect(
      TaskGridFilter.fromMap(<String, String>{'showBringup': 'false'}),
      TaskGridFilter()..showBringup = false,
    );
  });

  test('cross check on inequality', () {
    final defaultFilter = TaskGridFilter();
    final nonDefaultFilters = <TaskGridFilter>[
      TaskGridFilter()..taskFilter = RegExp('foo'),
      TaskGridFilter()..authorFilter = RegExp('foo'),
      TaskGridFilter()..messageFilter = RegExp('foo'),
      TaskGridFilter()..hashFilter = RegExp('foo'),
      TaskGridFilter()..showLinux = false,
    ];
    for (final filter in nonDefaultFilters) {
      expect(filter, isNot(equals(defaultFilter)));
      expect(defaultFilter, isNot(equals(filter)));
    }
    for (var i = 0; i < nonDefaultFilters.length; i++) {
      for (var j = 0; j < nonDefaultFilters.length; j++) {
        if (i == j) {
          expect(nonDefaultFilters[i], nonDefaultFilters[j]);
        } else {
          expect(nonDefaultFilters[i], isNot(equals(nonDefaultFilters[j])));
        }
      }
    }
  });

  test('bringup filter show all tasks', () {
    final filters = <TaskGridFilter>[TaskGridFilter()..showBringup = true];
    for (final filter in filters) {
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(Task()..builderName = 'Good task'),
        ),
        true,
      );
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(
            generateTaskForTest(
              status: TaskBox.statusSucceeded,
              builderName: 'Bringup task',
              bringup: true,
            ),
          ),
        ),
        true,
      );
    }
  });

  test('bringup filter hide bringup tasks', () {
    final filters = <TaskGridFilter>[TaskGridFilter()..showBringup = false];
    for (final filter in filters) {
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(Task()..builderName = 'Good task'),
        ),
        true,
      );
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(
            generateTaskForTest(
              status: TaskBox.statusSucceeded,
              builderName: 'Bringup task',
              bringup: true,
            ),
          ),
        ),
        false,
      );
    }
  });

  test('matches task name simple substring', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'taskFilter': 'foo'}),
      TaskGridFilter()..taskFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')),
        true,
      );
      expect(
        filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'Foo')),
        true,
      );
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(Task()..builderName = 'blah foo blah'),
        ),
        true,
      );
      expect(
        filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'fo')),
        false,
      );
    }
  });

  test('matches task name simple substring case insensitive', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'taskFilter': 'foo'}),
      TaskGridFilter()..taskFilter = RegExp('foo'),
      TaskGridFilter()..taskFilter = RegExp('FOO'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')),
        true,
      );
      expect(
        filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'Foo')),
        true,
      );
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(Task()..builderName = 'blah fOO blah'),
        ),
        true,
      );
      expect(
        filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'fo')),
        false,
      );
    }
  });

  test('matches task name regexp', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'taskFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..taskFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(Task()..builderName = 'z bc'),
        ),
        true,
      );
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(Task()..builderName = 'z bc z'),
        ),
        false,
      );
      expect(
        filter.matchesTask(
          QualifiedTask.fromTask(Task()..builderName = 'z b c'),
        ),
        false,
      );
      expect(
        filter.matchesTask(QualifiedTask.fromTask(Task()..builderName = 'foo')),
        false,
      );
    }
  });

  void testStage({
    required String taskName,
    required String fieldName,
    required TaskGridFilter trueFilter,
    required TaskGridFilter falseFilter,
  }) {
    final trueFilterMap = TaskGridFilter.fromMap(<String, String>{
      fieldName: 'true',
    });
    final falseFilterMap = TaskGridFilter.fromMap(<String, String>{
      fieldName: 'false',
    });

    expect(trueFilter, trueFilterMap);
    expect(trueFilter, isNot(equals(falseFilterMap)));
    expect(trueFilter, isNot(equals(falseFilter)));
    expect(falseFilter, falseFilterMap);
    expect(falseFilter, isNot(equals(trueFilterMap)));
    expect(falseFilter, isNot(equals(trueFilter)));

    expect(
      trueFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = taskName),
      ),
      true,
    );
    expect(
      trueFilterMap.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = taskName),
      ),
      true,
    );

    expect(
      falseFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = taskName),
      ),
      false,
    );
    expect(
      falseFilterMap.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = taskName),
      ),
      false,
    );
  }

  const showOSs = <String, String>{
    'showMac': 'Mac',
    'showWindows': 'Windows',
    'showiOS': 'ios',
    'showLinux': 'Linux',
    'showAndroid': 'Android',
  };
  for (var os in showOSs.entries) {
    test('matches ${os.value} stage', () {
      testStage(
        taskName: os.value,
        fieldName: os.key,
        trueFilter: TaskGridFilter.fromMap(<String, String>{os.key: 'true'}),
        falseFilter: TaskGridFilter.fromMap(<String, String>{os.key: 'false'}),
      );
    });
  }

  test('matches ios and android filters logic', () {
    final iosMacFilter = TaskGridFilter.fromMap(<String, String>{
      'showMac': 'false',
      'showiOS': 'true',
    });
    final macIosFilter = TaskGridFilter.fromMap(<String, String>{
      'showMac': 'true',
      'showiOS': 'false',
    });
    final macIosBothTrueFilter = TaskGridFilter.fromMap(<String, String>{
      'showMac': 'true',
      'showiOS': 'true',
    });

    final androidLinuxFilter = TaskGridFilter.fromMap(<String, String>{
      'showLinux': 'false',
      'showAndroid': 'true',
    });
    final linuxAndroidFilter = TaskGridFilter.fromMap(<String, String>{
      'showLinux': 'true',
      'showAndroid': 'false',
    });
    final linuxAndroidBothTrueFilter = TaskGridFilter.fromMap(<String, String>{
      'showLinux': 'true',
      'showAndroid': 'true',
    });
    final androidFalseFilter = TaskGridFilter.fromMap(<String, String>{
      'showAndroid': 'false',
    });

    expect(
      iosMacFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Mac_ios'),
      ),
      true,
    );
    expect(
      iosMacFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Mac'),
      ),
      false,
    );
    expect(
      macIosFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Mac_ios'),
      ),
      false,
    );
    expect(
      macIosFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Mac'),
      ),
      true,
    );
    expect(
      macIosBothTrueFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Mac_ios'),
      ),
      true,
    );
    expect(
      macIosBothTrueFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Mac'),
      ),
      true,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_android'),
      ),
      true,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_mokey'),
      ),
      true,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_pixel_7pro'),
      ),
      true,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux pixel_test'),
      ),
      false,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux'),
      ),
      false,
    );
    expect(
      linuxAndroidFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_android'),
      ),
      false,
    );
    expect(
      linuxAndroidFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_mokey'),
      ),
      false,
    );
    expect(
      linuxAndroidFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_pixel_7pro'),
      ),
      false,
    );
    expect(
      linuxAndroidFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux'),
      ),
      true,
    );
    expect(
      linuxAndroidBothTrueFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_android'),
      ),
      true,
    );
    expect(
      linuxAndroidBothTrueFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_mokey'),
      ),
      true,
    );
    expect(
      linuxAndroidBothTrueFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Linux_pixel_7pro'),
      ),
      true,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Windows_android'),
      ),
      true,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Windows_mokey'),
      ),
      true,
    );
    expect(
      androidLinuxFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Windows_pixel_7pro'),
      ),
      true,
    );
    expect(
      androidFalseFilter.matchesTask(
        QualifiedTask.fromTask(Task()..builderName = 'Anything_android'),
      ),
      false,
    );
  });

  test('matches author name simple substring', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'authorFilter': 'foo'}),
      TaskGridFilter()..authorFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..author = 'foo', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..author = 'blah foo blah', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..author = 'fo', tasks: []),
        ),
        false,
      );
    }
  });

  test('matches author name regexp', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'authorFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..authorFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..author = 'z bc', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..author = 'z bc z', tasks: []),
        ),
        false,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..author = 'z b c', tasks: []),
        ),
        false,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..author = 'foo', tasks: []),
        ),
        false,
      );
    }
  });

  test('matches commit message simple substring', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'messageFilter': 'foo'}),
      TaskGridFilter()..messageFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..message = 'foo', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..message = 'blah foo blah', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..message = 'fo', tasks: []),
        ),
        false,
      );
    }
  });

  test('matches commit message regexp', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'messageFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..messageFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..message = 'z bc', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..message = 'z bc z', tasks: []),
        ),
        false,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..message = 'z b c', tasks: []),
        ),
        false,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..message = 'foo', tasks: []),
        ),
        false,
      );
    }
  });

  test('matches commit sha simple substring', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'hashFilter': 'foo'}),
      TaskGridFilter()..hashFilter = RegExp('foo'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..sha = 'foo', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..sha = 'blah foo blah', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..sha = 'fo', tasks: []),
        ),
        false,
      );
    }
  });

  test('matches commit sha regexp', () {
    final filters = <TaskGridFilter>[
      TaskGridFilter.fromMap(<String, String>{'hashFilter': '.*[ab][cd]\$'}),
      TaskGridFilter()..hashFilter = RegExp('.*[ab][cd]\$'),
    ];
    expect(filters[0], filters[1]);
    for (final filter in filters) {
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..sha = 'z bc', tasks: []),
        ),
        true,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..sha = 'z bc z', tasks: []),
        ),
        false,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..sha = 'z b c', tasks: []),
        ),
        false,
      );
      expect(
        filter.matchesCommit(
          CommitStatus(commit: Commit()..sha = 'foo', tasks: []),
        ),
        false,
      );
    }
  });

  group('filter.toMap()', () {
    test('adds key-value pairs that are non-default', () {
      final showAndroidFalseNonDefault = TaskGridFilter()..showAndroid = false;
      expect(showAndroidFalseNonDefault.toMap(), {'showAndroid': 'false'});
    });

    test('ignores key-value pairs that are default', () {
      final showAndroidTrueIsDefault = TaskGridFilter()..showAndroid = true;
      expect(showAndroidTrueIsDefault.toMap(), isEmpty);
    });

    test('ignores existing key-value pairs that are not filter keys', () {
      final showAndroidTrueIsDefault = TaskGridFilter()..showAndroid = true;
      expect(showAndroidTrueIsDefault.toMap(initialMap: {'foo': 'bar'}), {
        'foo': 'bar',
      });
    });

    test('removes existing key-value pairs that are now default values', () {
      final showAndroidTrueIsDefault = TaskGridFilter()..showAndroid = true;
      expect(
        showAndroidTrueIsDefault.toMap(initialMap: {'showAndroid': 'false'}),
        isEmpty,
      );
    });
  });
}
