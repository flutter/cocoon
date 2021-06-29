// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:app_flutter/logic/task_grid_filter.dart';
import 'package:app_flutter/model/commit.pb.dart';
import 'package:app_flutter/model/commit_status.pb.dart';
import 'package:app_flutter/model/task.pb.dart';
import 'package:app_flutter/service/dev_cocoon.dart';
import 'package:app_flutter/state/build.dart';
import 'package:app_flutter/widgets/commit_box.dart';
import 'package:app_flutter/widgets/lattice.dart';
import 'package:app_flutter/widgets/state_provider.dart';
import 'package:app_flutter/widgets/task_box.dart';
import 'package:app_flutter/widgets/task_grid.dart';
import 'package:app_flutter/widgets/task_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_build.dart';
import '../utils/golden.dart';
import '../utils/mocks.dart';
import '../utils/task_icons.dart';

void main() {
  testWidgets('TaskGridContainer shows loading indicator when statuses is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<BuildState>(
          value: FakeBuildState(),
          child: const Material(
            child: TaskGridContainer(),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LatticeScrollView), findsNothing);
  });

  testWidgets('TaskGridContainer with DevelopmentCocoonService', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final BuildState buildState = BuildState(
      cocoonService: DevelopmentCocoonService(DateTime.utc(2020)),
      authService: MockGoogleSignInService(),
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<BuildState>(
          value: buildState,
          child: const Material(
            child: TaskGridContainer(),
          ),
        ),
      ),
    );
    await tester.pump();

    final int commitCount = tester.elementList(find.byType(CommitBox)).length;
    expect(commitCount, 16); // based on screen size this is how many show up

    final double xPosition = tester.getTopLeft(find.byType(CommitBox).first).dx;

    for (int index = 0; index < commitCount; index += 1) {
      // All the x positions should match the first instance if they're all in the same column
      expect(tester.getTopLeft(find.byType(CommitBox).at(index)).dx, xPosition);
    }

    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.origin.png');

    // Check if the LOADING... indicator appears.
    await tester.drag(find.byType(TaskGrid), const Offset(0.0, -5000.0));
    await tester.pump();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_y.png');

    // Check the right edge after the data comes in.
    await tester.drag(find.byType(TaskGrid), const Offset(-5000.0, 0.0));
    await tester.pump();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_x.png');

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('TaskGridContainer with DevelopmentCocoonService - dark', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final BuildState buildState = BuildState(
      cocoonService: DevelopmentCocoonService(DateTime.utc(2020)),
      authService: MockGoogleSignInService(),
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ValueProvider<BuildState>(
          value: buildState,
          child: const Material(
            child: TaskGridContainer(),
          ),
        ),
      ),
    );
    await tester.pump();

    final int commitCount = tester.elementList(find.byType(CommitBox)).length;
    expect(commitCount, 16); // based on screen size this is how many show up

    final double xPosition = tester.getTopLeft(find.byType(CommitBox).first).dx;

    for (int index = 0; index < commitCount; index += 1) {
      // All the x positions should match the first instance if they're all in the same column
      expect(tester.getTopLeft(find.byType(CommitBox).at(index)).dx, xPosition);
    }

    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.origin.dark.png');

    // Check if the LOADING... indicator appears.
    await tester.drag(find.byType(TaskGrid), const Offset(0.0, -5000.0));
    await tester.pump();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_y.dark.png');

    // Check the right edge after the data comes in.
    await tester.drag(find.byType(TaskGrid), const Offset(-5000.0, 0.0));
    await tester.pump();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_x.dark.png');

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  Future<void> testGrid(WidgetTester tester, TaskGridFilter filter, int rows, int cols) async {
    final BuildState buildState = BuildState(
      cocoonService: DevelopmentCocoonService(DateTime.utc(2020)),
      authService: MockGoogleSignInService(),
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ValueProvider<BuildState>(
          value: buildState,
          child: Material(
            child: TaskGridContainer(filter: filter),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LatticeScrollView), findsOneWidget);
    final LatticeScrollView lattice = find.byType(LatticeScrollView).evaluate().first.widget;

    expect(lattice.cells.length, rows);
    for (final List<LatticeCell> row in lattice.cells) {
      expect(row.length, cols);
    }

    await tester.pumpWidget(Container());
    buildState.dispose();
  }

  testWidgets('Task name filter affects grid', (WidgetTester tester) async {
    // Default filters
    await testGrid(tester, null, 27, 111);
    await testGrid(tester, TaskGridFilter(), 27, 111);
    await testGrid(tester, TaskGridFilter.fromMap(null), 27, 111);

    // QualifiedTask (column) filters
    await testGrid(tester, TaskGridFilter()..taskFilter = RegExp('task 2'), 27, 30);
    await testGrid(tester, TaskGridFilter()..showCirrus = false, 27, 109);
    await testGrid(tester, TaskGridFilter()..showLuci = false, 27, 111);

    // CommitStatus (row) filters
    await testGrid(tester, TaskGridFilter()..authorFilter = RegExp('bob'), 8, 111);
    await testGrid(tester, TaskGridFilter()..messageFilter = RegExp('developer'), 18, 111);
    await testGrid(tester, TaskGridFilter()..hashFilter = RegExp('c'), 20, 111);
  });

  testWidgets('Skipped tasks do not break the grid', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    // Matrix Diagram:
    //
    // ✓☐☐
    // ☐✓☐
    // ☐☐✓
    //
    // To construct the matrix from this diagram, each [CommitStatus] must have a unique [Task]
    // that does not share its name with any other [Task]. This will make that [CommitStatus] have
    // its task on its own unique row and column.

    final List<CommitStatus> statusesWithSkips = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..status = TaskBox.statusSucceeded
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..status = TaskBox.statusSucceeded
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..status = TaskBox.statusSucceeded
          ],
        )
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskGrid(
            buildState: FakeBuildState(),
            commitStatuses: statusesWithSkips,
          ),
        ),
      ),
    );

    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.withSkips.png');
  });

  testWidgets('TaskGrid creates a task icon row and they line up', (WidgetTester tester) async {
    final List<CommitStatus> commitStatuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..name = 'Task Name'
              ..stageName = 'Stage Nome 1'
              ..status = TaskBox.statusSucceeded,
            Task()
              ..name = 'Task Name'
              ..stageName = 'Stage Nome 2'
              ..status = TaskBox.statusFailed
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskGrid(
            buildState: FakeBuildState(),
            commitStatuses: commitStatuses,
          ),
        ),
      ),
    );

    expect(find.byType(TaskIcon), findsNWidgets(2));
    expect(tester.getTopLeft(find.byType(TaskIcon).at(0)).dy, tester.getTopLeft(find.byType(TaskIcon).at(1)).dy);
  });

  testWidgets('TaskGrid honors moreStatusesExist', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final List<CommitStatus> commitStatuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..name = 'Task Name'
              ..stageName = 'Stage Nome'
              ..status = TaskBox.statusSucceeded
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskGrid(
            buildState: FakeBuildState(moreStatusesExist: false),
            commitStatuses: commitStatuses,
          ),
        ),
      ),
    );

    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.withoutL.png');

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskGrid(
            buildState: FakeBuildState(moreStatusesExist: true),
            commitStatuses: commitStatuses,
          ),
        ),
      ),
    );

    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.withL.png');
  });

  testWidgets('TaskGrid shows icon for rerun tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskGrid(
            buildState: FakeBuildState(
              authService: MockGoogleSignInService(),
              cocoonService: MockCocoonService(),
            ),
            commitStatuses: <CommitStatus>[
              CommitStatus()
                ..commit = (Commit()..author = 'Cast')
                ..tasks.addAll(
                  <Task>[
                    Task()
                      ..stageName = 'A'
                      ..status = 'Succeeded'
                      ..attempts = 2
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.priority_high), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskGrid(
            buildState: FakeBuildState(
              authService: MockGoogleSignInService(),
              cocoonService: MockCocoonService(),
            ),
            commitStatuses: <CommitStatus>[
              CommitStatus()
                ..commit = (Commit()..author = 'Cast')
                ..tasks.addAll(
                  <Task>[
                    Task()
                      ..stageName = 'A'
                      ..status = 'Succeeded'
                      ..attempts = 1
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.priority_high), findsNothing);
  });

  testWidgets('TaskGrid can handle all the various different statuses', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final List<CommitStatus> statuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value'
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..attempts = 2
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..attempts = 2
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..attempts = 2
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..attempts = 2
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..attempts = 2
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value'
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..isFlaky = true
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..isFlaky = true
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..isFlaky = true
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..isFlaky = true
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..isFlaky = true
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value'
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value'
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskGrid(
            buildState: FakeBuildState(),
            commitStatuses: statuses,
          ),
        ),
      ),
    );

    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.differentTypes.png');
  });

  // Table Driven Approach to ensure every message does show the corresponding color
  TaskBox.statusColor.forEach((String message, Color color) {
    testWidgets('Is the color $color when given the message $message', (WidgetTester tester) async {
      await expectTaskBoxColorWithMessage(tester, message, color);
    });
  });
}

Future<void> expectTaskBoxColorWithMessage(WidgetTester tester, String message, Color expectedColor) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: Center(
          child: SizedBox(
            height: TaskBox.cellSize * 3.0,
            width: TaskBox.cellSize * 3.0,
            child: RepaintBoundary(
              child: TaskGrid(
                buildState: FakeBuildState(
                  authService: MockGoogleSignInService(),
                  cocoonService: MockCocoonService(),
                ),
                commitStatuses: <CommitStatus>[
                  CommitStatus()
                    ..commit = (Commit()..author = 'Mathilda')
                    ..tasks.addAll(
                      <Task>[Task()..status = message],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final RenderRepaintBoundary renderObject = tester.renderObject(find.byType(TaskGrid)).parent as RenderRepaintBoundary;
  final ByteData pixels = await tester.runAsync<ByteData>(() async {
    return await (await renderObject.toImage()).toByteData();
  });
  assert(pixels.lengthInBytes == ((TaskBox.cellSize * 3.0) * (TaskBox.cellSize * 3.0) * 4).round());
  const double padding = 4.0;
  final int rgba = pixels
      .getUint32(((((TaskBox.cellSize * 3.0) * (TaskBox.cellSize + padding)) + TaskBox.cellSize + padding).ceil()) * 4);
  expect((rgba >> 8) | (rgba << 24) & 0xFFFFFFFF, expectedColor.value);
}
