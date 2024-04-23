// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app_icons/flutter_app_icons_platform_interface.dart';
import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/logic/task_grid_filter.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/commit_status.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/service/dev_cocoon.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:flutter_dashboard/widgets/commit_box.dart';
import 'package:flutter_dashboard/widgets/lattice.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_dashboard/widgets/task_box.dart';
import 'package:flutter_dashboard/widgets/task_grid.dart';
import 'package:flutter_dashboard/widgets/task_icon.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_build.dart';
import '../utils/fake_flutter_app_icons.dart';
import '../utils/golden.dart';
import '../utils/mocks.dart';
import '../utils/task_icons.dart';

const double _cellSize = 36;

void main() {
  setUp(() {
    FlutterAppIconsPlatform.instance = FakeFlutterAppIcons();
  });

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
    final DevelopmentCocoonService service = DevelopmentCocoonService(DateTime.utc(2020));
    final BuildState buildState = BuildState(
      cocoonService: service,
      authService: MockGoogleSignInService(),
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      TaskBox(
        cellSize: _cellSize,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: ValueProvider<BuildState>(
            value: buildState,
            child: const Material(
              child: TaskGridContainer(),
            ),
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
    service.paused = true;
    await tester.drag(find.byType(TaskGrid), const Offset(0.0, -5000.0));
    await tester.pumpAndSettle();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_y.png');
    service.paused = false;
    await tester.pumpAndSettle();

    // Check the right edge after the data comes in.
    service.paused = true;
    await tester.drag(find.byType(TaskGrid), const Offset(-5000.0, 0.0));
    await tester.pumpAndSettle();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_x.png');
    service.paused = false;
    await tester.pumpAndSettle();

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('TaskGridContainer supports mouse drag', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final DevelopmentCocoonService service = DevelopmentCocoonService(DateTime.utc(2020));
    final BuildState buildState = BuildState(
      cocoonService: service,
      authService: MockGoogleSignInService(),
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      TaskBox(
        cellSize: _cellSize,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: ValueProvider<BuildState>(
            value: buildState,
            child: const Material(
              child: TaskGridContainer(),
            ),
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
    service.paused = true;

    TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(TaskGrid)),
      kind: PointerDeviceKind.mouse,
    );
    for (int i = 0; i < 100; i += 1) {
      await gesture.moveBy(const Offset(0.0, -50.0));
    }
    await gesture.up();

    await tester.pumpAndSettle();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.mouse_scroll_y.png');

    await gesture.removePointer();
    service.paused = false;
    await tester.pumpAndSettle();

    // Check the right edge after the data comes in.
    service.paused = true;

    gesture = await tester.startGesture(
      tester.getCenter(find.byType(TaskGrid)),
      kind: PointerDeviceKind.mouse,
    );

    for (int i = 0; i < 100; i += 1) {
      await gesture.moveBy(const Offset(-50.0, 0));
    }
    //await gesture.moveBy(const Offset(-5000, 0));
    await gesture.up();

    await tester.pumpAndSettle();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.mouse_scroll_x.png');

    service.paused = false;
    await gesture.removePointer();

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('TaskGridContainer with DevelopmentCocoonService - dark', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final DevelopmentCocoonService service = DevelopmentCocoonService(DateTime.utc(2020));
    final BuildState buildState = BuildState(
      cocoonService: service,
      authService: MockGoogleSignInService(),
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      TaskBox(
        cellSize: _cellSize,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: false),
          home: ValueProvider<BuildState>(
            value: buildState,
            child: const Material(
              child: TaskGridContainer(),
            ),
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
    service.paused = true;
    await tester.drag(find.byType(TaskGrid), const Offset(0.0, -5000.0));
    await tester.pumpAndSettle();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_y.dark.png');
    service.paused = false;
    await tester.pumpAndSettle();

    // Check the right edge after the data comes in.
    service.paused = true;
    await tester.drag(find.byType(TaskGrid), const Offset(-5000.0, 0.0));
    await tester.pumpAndSettle();
    await expectGoldenMatches(find.byType(TaskGrid), 'task_grid_test.dev.scroll_x.dark.png');
    service.paused = false;
    await tester.pumpAndSettle();

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  Future<void> testGrid(WidgetTester tester, TaskGridFilter? filter, int rows, int cols) async {
    final BuildState buildState = BuildState(
      cocoonService: DevelopmentCocoonService(DateTime.utc(2020)),
      authService: MockGoogleSignInService(),
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      TaskBox(
        cellSize: _cellSize,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: ValueProvider<BuildState>(
            value: buildState,
            child: Material(
              child: TaskGridContainer(filter: filter),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LatticeScrollView), findsOneWidget);
    final LatticeScrollView lattice = find.byType(LatticeScrollView).evaluate().first.widget as LatticeScrollView;

    expect(lattice.cells.length, rows);
    for (final List<LatticeCell> row in lattice.cells) {
      expect(row.length, cols);
    }

    await tester.pumpWidget(Container());
    buildState.dispose();
  }

  testWidgets('Task name filter affects grid', (WidgetTester tester) async {
    // Default filters
    await testGrid(tester, null, 27, 101);
    await testGrid(tester, TaskGridFilter(), 27, 101);
    await testGrid(tester, TaskGridFilter.fromMap(null), 27, 101);

    // QualifiedTask (column) filters
    await testGrid(tester, TaskGridFilter()..taskFilter = RegExp('Linux_android 2'), 27, 12);

    // CommitStatus (row) filters
    await testGrid(tester, TaskGridFilter()..authorFilter = RegExp('bob'), 8, 101);
    await testGrid(tester, TaskGridFilter()..messageFilter = RegExp('developer'), 18, 101);
    await testGrid(tester, TaskGridFilter()..hashFilter = RegExp('2d22b5e85f986f3fa2cf1bfaf085905c2182c270'), 4, 101);
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
              ..builderName = '1'
              ..status = TaskBox.statusSucceeded,
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..builderName = '2'
              ..status = TaskBox.statusSucceeded,
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..builderName = '3'
              ..status = TaskBox.statusSucceeded,
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
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

  testWidgets('Cocoon and LUCI tasks share the same column', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    // Matrix Diagram:
    //
    // ✓
    // ✓
    //
    // To construct the matrix from this diagram, each [CommitStatus] will have a [Task]
    // that shares its name, but will have a different stage name.

    final List<CommitStatus> statuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..name = '1'
              ..builderName = '1'
              ..status = TaskBox.statusSucceeded,
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = StageName.luci
              ..name = '1'
              ..builderName = '1'
              ..status = TaskBox.statusSucceeded,
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

    expect(find.byType(LatticeScrollView), findsOneWidget);
    final LatticeScrollView lattice = find.byType(LatticeScrollView).evaluate().first.widget as LatticeScrollView;

    // Rows (task icon, two commits, load more row)
    expect(lattice.cells.length, 4);
    // Columns (commit box, task)
    expect(lattice.cells.first.length, 2);
    expect(lattice.cells[1].length, 2);
  });

  testWidgets('TaskGrid creates a task icon row and they line up', (WidgetTester tester) async {
    final List<CommitStatus> commitStatuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..name = 'Task Name 1'
              ..builderName = 'Task Name 1'
              ..status = TaskBox.statusSucceeded,
            Task()
              ..name = 'Task Name 2'
              ..builderName = 'Task Name 2'
              ..status = TaskBox.statusFailed,
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
              ..name = 'Task Name'
              ..stageName = 'Stage Nome'
              ..status = TaskBox.statusSucceeded,
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
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
        theme: ThemeData(useMaterial3: false),
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
                      ..attempts = 2,
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
                      ..attempts = 1,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.priority_high), findsNothing);
  });

  testWidgets('TaskGrid shows icon for isTestFlaky tasks', (WidgetTester tester) async {
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
                      ..isTestFlaky = true,
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
                      ..isTestFlaky = false,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.priority_high), findsNothing);
  });

  testWidgets('TaskGrid shows icon for isTestFlaky tasks with multiple attempts', (WidgetTester tester) async {
    final Task taskA3 = Task()
      ..stageName = 'A'
      ..builderName = '1'
      ..name = 'A'
      ..status = TaskBox.statusSucceeded
      ..attempts = 3
      ..isTestFlaky = true;

    final Task taskB1 = Task()
      ..stageName = 'B'
      ..builderName = '2'
      ..name = 'B'
      ..status = TaskBox.statusSucceeded
      ..attempts = 1
      ..isTestFlaky = false;

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
                    taskA3,
                  ],
                ),
              CommitStatus()
                ..commit = (Commit()..author = 'Cast')
                ..tasks.addAll(
                  <Task>[taskB1],
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.priority_high), findsNWidgets(1));

    // check the order of the items. The flaky should be to the left and first.
    expect(find.byType(TaskGrid).first, findsAtLeastNWidgets(1));

    final LatticeScrollView latticeScrollView = tester.firstWidget(find.byType(LatticeScrollView));
    final List<List<LatticeCell>> cells = latticeScrollView.cells;
    final List<LatticeCell> myCells = cells.first;
    expect(myCells.length, 3);
    myCells.removeAt(0); // the first element is the github author box.
    expect(myCells[0].taskName, '1');
    expect(myCells[1].taskName, '2');
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
              ..builderName = '1'
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..builderName = '2'
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..builderName = '3'
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..builderName = '4'
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..builderName = '5'
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value',
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..builderName = '1'
              ..attempts = 2
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..builderName = '2'
              ..attempts = 2
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..builderName = '3'
              ..attempts = 2
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..builderName = '4'
              ..attempts = 2
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..builderName = '5'
              ..attempts = 2
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value',
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..builderName = '1'
              ..isFlaky = true
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..builderName = '2'
              ..isFlaky = true
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..builderName = '3'
              ..isFlaky = true
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..builderName = '4'
              ..isFlaky = true
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..builderName = '5'
              ..isFlaky = true
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value',
          ],
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..tasks.addAll(
          <Task>[
            Task()
              ..stageName = 'A'
              ..name = '1'
              ..builderName = '1'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusFailed,
            Task()
              ..stageName = 'A'
              ..name = '2'
              ..builderName = '2'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusNew,
            Task()
              ..stageName = 'A'
              ..name = '3'
              ..builderName = '3'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusSkipped,
            Task()
              ..stageName = 'A'
              ..name = '4'
              ..builderName = '4'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusSucceeded,
            Task()
              ..stageName = 'A'
              ..name = '5'
              ..builderName = '5'
              ..attempts = 2
              ..isFlaky = true
              ..status = TaskBox.statusInProgress,
            Task()..status = 'Invalid value',
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
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
  const double cellSize = 18;
  const double cellPixelSize = cellSize * 3.0;
  const double cellPixelArea = cellPixelSize * cellPixelSize;
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: Center(
          child: SizedBox(
            height: cellPixelSize,
            width: cellPixelSize,
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
  final RenderRepaintBoundary? renderObject =
      tester.renderObject(find.byType(TaskGrid)).parent as RenderRepaintBoundary?;
  final ByteData? pixels = await tester.runAsync<ByteData?>(() async {
    return (await renderObject!.toImage()).toByteData();
  });
  expect(pixels!.lengthInBytes, (cellPixelArea * 4).round());
  const double padding = 4.0;
  final int rgba = pixels.getUint32((((cellPixelSize * (cellSize + padding)) + cellSize + padding).ceil()) * 4);
  expect((rgba >> 8) | (rgba << 24) & 0xFFFFFFFF, expectedColor.value);
}
