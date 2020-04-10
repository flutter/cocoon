// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Commit, CommitStatus, Stage, Task;

import 'package:app_flutter/service/dev_cocoon.dart';
import 'package:app_flutter/state/build.dart';
import 'package:app_flutter/widgets/commit_box.dart';
import 'package:app_flutter/widgets/lattice.dart';
import 'package:app_flutter/widgets/pulse.dart';
import 'package:app_flutter/widgets/state_provider.dart';
import 'package:app_flutter/widgets/task_grid.dart';
import 'package:app_flutter/widgets/task_box.dart';
import 'package:app_flutter/widgets/task_icon.dart';

import '../utils/fake_build.dart';
import '../utils/mocks.dart';

Future<void> precacheAssets(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final Image widget in TaskIcon.stageIcons.values) {
      await precacheImage(
        widget.image,
        tester.element(find.byType(TaskGrid)),
      );
    }
  });
  await tester.pump();
}

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
    await precacheAssets(tester);

    final int commitCount = tester.elementList(find.byType(CommitBox)).length;
    expect(commitCount, 16); // based on screen size this is how many show up

    final double xPosition = tester.getTopLeft(find.byType(CommitBox).first).dx;

    for (int index = 0; index < commitCount; index += 1) {
      // All the x positions should match the first instance if they're all in the same column
      expect(tester.getTopLeft(find.byType(CommitBox).at(index)).dx, xPosition);
    }

    await expectLater(find.byType(TaskGrid), matchesGoldenFile('task_grid_test.dev.origin.png'));

    // Check if the LOADING... indicator appears.
    await tester.drag(find.byType(TaskGrid), const Offset(0.0, -5000.0));
    await tester.pump();
    await expectLater(find.byType(TaskGrid), matchesGoldenFile('task_grid_test.dev.scroll_y.png'));

    // Check the right edge after the data comes in.
    await tester.drag(find.byType(TaskGrid), const Offset(-5000.0, 0.0));
    await tester.pump();
    await expectLater(find.byType(TaskGrid), matchesGoldenFile('task_grid_test.dev.scroll_x.png'));

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('Skipped tasks do not break the grid', (WidgetTester tester) async {
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
        ..stages.add(Stage()
          ..name = 'A'
          ..tasks.addAll(<Task>[
            Task()
              ..name = '1'
              ..status = TaskBox.statusSucceeded
          ])),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(Stage()
          ..name = 'A'
          ..tasks.addAll(<Task>[
            Task()
              ..name = '2'
              ..status = TaskBox.statusSucceeded
          ])),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(Stage()
          ..name = 'A'
          ..tasks.addAll(<Task>[
            Task()
              ..name = '3'
              ..status = TaskBox.statusSucceeded
          ]))
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
    await precacheAssets(tester);

    await expectLater(find.byType(TaskGrid), matchesGoldenFile('task_grid_test.withSkips.png'));
  });

  testWidgets('TaskGrid creates a task icon row and they line up', (WidgetTester tester) async {
    final List<CommitStatus> commitStatuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(
          Stage()
            ..name = 'Stage Name 1'
            ..tasks.addAll(
              <Task>[
                Task()
                  ..name = 'Task Name'
                  ..stageName = 'Stage Nome 1'
                  ..status = TaskBox.statusSucceeded
              ],
            ),
        )
        ..stages.add(
          Stage()
            ..name = 'Stage Name 2'
            ..tasks.addAll(
              <Task>[
                Task()
                  ..name = 'Task Name'
                  ..stageName = 'Stage Nome 2'
                  ..status = TaskBox.statusFailed
              ],
            ),
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
    final List<CommitStatus> commitStatuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(
          Stage()
            ..name = 'Stage Name'
            ..tasks.addAll(
              <Task>[
                Task()
                  ..name = 'Task Name'
                  ..stageName = 'Stage Nome'
                  ..status = TaskBox.statusSucceeded
              ],
            ),
        )
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
    await precacheAssets(tester);

    await expectLater(find.byType(TaskGrid), matchesGoldenFile('task_grid_test.withoutL.png'));

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

    await expectLater(find.byType(TaskGrid), matchesGoldenFile('task_grid_test.withL.png'));
  });

  testWidgets('TaskGrid shows loading indicator for In Progress task', (WidgetTester tester) async {
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
                ..stages.add(
                  Stage()
                    ..tasks.addAll(
                      <Task>[Task()..status = 'In Progress'],
                    ),
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(Pulse), findsOneWidget);
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
                ..stages.add(
                  Stage()
                    ..tasks.addAll(
                      <Task>[Task()..status = 'Succeeded'],
                    ),
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(Pulse), findsNothing);
  });

  testWidgets('TaskGrid can handle all the various different statuses', (WidgetTester tester) async {
    final List<CommitStatus> statuses = <CommitStatus>[
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(
          Stage()
            ..name = 'A'
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
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(
          Stage()
            ..name = 'A'
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
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(
          Stage()
            ..name = 'A'
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
        ),
      CommitStatus()
        ..commit = (Commit()..author = 'Author')
        ..stages.add(
          Stage()
            ..name = 'A'
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
    await precacheAssets(tester);

    await expectLater(find.byType(TaskGrid), matchesGoldenFile('task_grid_test.differentTypes.png'));
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
                    ..stages.add(
                      Stage()
                        ..tasks.addAll(
                          <Task>[Task()..status = message],
                        ),
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
