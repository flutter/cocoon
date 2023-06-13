// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_icons/flutter_app_icons_platform_interface.dart';
import 'package:flutter_dashboard/build_dashboard_page.dart';
import 'package:flutter_dashboard/model/branch.pb.dart';
import 'package:flutter_dashboard/model/build_status_response.pb.dart';
import 'package:flutter_dashboard/model/commit_status.pb.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/service/dev_cocoon.dart';
import 'package:flutter_dashboard/service/google_authentication.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:flutter_dashboard/widgets/error_brook_watcher.dart';
import 'package:flutter_dashboard/widgets/user_sign_in.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_dashboard/widgets/task_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'utils/fake_build.dart';
import 'utils/fake_flutter_app_icons.dart';
import 'utils/fake_google_account.dart';
import 'utils/golden.dart';
import 'utils/mocks.dart';
import 'utils/output.dart';
import 'utils/task_icons.dart';

void main() {
  late MockGoogleSignInService fakeAuthService;

  final Type dropdownButtonType = DropdownButton<String>(
    onChanged: (_) {},
    items: const <DropdownMenuItem<String>>[],
  ).runtimeType;

  void configureView(TestFlutterView view) {
    // device pixel ratio of 1.0 works well on web app and emulator
    // If not set, flutter test uses a Pixel 4 device pixel ratio of roughly 2.75, which doesn't quite work
    // I am using the default settings of Pixel 4 in this test, as referenced in the link below
    // https://android.googlesource.com/platform/external/qemu/+/b5b78438ae9ff3b90aafdab0f4f25585affc22fb/android/avd/hardware-properties.ini
    view.devicePixelRatio = 1.0;
    view.physicalSize = const Size(1080, 2280);
    addTearDown(view.reset);
  }

  setUp(() {
    fakeAuthService = MockGoogleSignInService();
    when(fakeAuthService.isAuthenticated).thenReturn(true);
    when(fakeAuthService.user).thenReturn(FakeGoogleSignInAccount());

    FlutterAppIconsPlatform.instance = FakeFlutterAppIcons();
  });

  testWidgets('shows sign in button', (WidgetTester tester) async {
    configureView(tester.view);
    final MockCocoonService fakeCocoonService = MockCocoonService();
    throwOnMissingStub(fakeCocoonService);
    when(fakeCocoonService.fetchFlutterBranches()).thenAnswer((_) => Completer<CocoonResponse<List<Branch>>>().future);
    when(fakeCocoonService.fetchRepos()).thenAnswer((_) => Completer<CocoonResponse<List<String>>>().future);
    when(
      fakeCocoonService.fetchCommitStatuses(
        branch: anyNamed('branch'),
        repo: anyNamed('repo'),
      ),
    ).thenAnswer((_) => Completer<CocoonResponse<List<CommitStatus>>>().future);
    when(
      fakeCocoonService.fetchTreeBuildStatus(
        branch: anyNamed('branch'),
        repo: anyNamed('repo'),
      ),
    ).thenAnswer((_) => Completer<CocoonResponse<BuildStatusResponse>>().future);

    final BuildState buildState = BuildState(
      cocoonService: fakeCocoonService,
      authService: fakeAuthService,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: buildState,
          child: ValueProvider<GoogleSignInService>(
            value: buildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );
    expect(find.byType(UserSignIn), findsOneWidget);

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('shows settings button', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('shows file a bug button', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bug_report), findsOneWidget);
  });

  testWidgets('shows key button & legend', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump();

    for (final String status in TaskBox.statusColor.keys) {
      expect(find.text(status), findsOneWidget);
    }
    expect(find.text('Flaky'), findsOneWidget);
    expect(find.text('Ran more than once'), findsOneWidget);
  });

  testWidgets('shows branch and repo dropdown button when screen is decently large', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.byType(dropdownButtonType), findsNWidgets(2));

    expect(find.text('repo: '), findsOneWidget);
    expect((tester.widget(find.byKey(const Key('repo dropdown'))) as DropdownButton).value, equals('flutter'));

    expect(find.text('branch: '), findsOneWidget);
    expect((tester.widget(find.byKey(const Key('branch dropdown'))) as DropdownButton).value, equals('master'));
  });

  testWidgets('shows enabled Refresh GitHub Commits button when isAuthenticated', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    // Open settings overlay
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Finish the menu animation.

    final Finder labelFinder = find.text('Refresh GitHub Commits');

    expect(labelFinder, findsOneWidget);

    final TextButton button = tester.element(labelFinder).findAncestorWidgetOfExactType<TextButton>()!;

    expect(button.onPressed, isNotNull, reason: 'The button should have a non-null onPressed attribute.');
  });

  testWidgets('shows disabled Refresh GitHub Commits button when !isAuthenticated', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;
    when(fakeAuthService.isAuthenticated).thenReturn(false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    // Open settings overlay
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Finish the menu animation.

    final Finder labelFinder = find.text('Refresh GitHub Commits');
    final TextButton button = tester.element(labelFinder).findAncestorWidgetOfExactType<TextButton>()!;

    expect(button.onPressed, isNull, reason: 'The button should have a null onPressed attribute.');
  });

  testWidgets('shows loading when fetch tree status is null', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()
      ..isTreeBuilding = null
      ..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Loading...'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.grey[850]);
    expect(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('shows loading when fetch tree status is null, dark mode', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()
      ..isTreeBuilding = null
      ..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Loading...'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.grey[850]);
    expect(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('shows tree closed when fetch tree status is false', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()
      ..isTreeBuilding = false
      ..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    // Verify the "Tree is Closed" message is wrapped in a [Tooltip].
    final Finder tooltipFinder = find.byWidgetPredicate((Widget widget) {
      return widget is Tooltip && (widget.message?.contains('Tree is Closed') ?? false);
    });
    expect(tooltipFinder, findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.red);
    expect(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('shows tree closed when fetch tree status is false, dark mode', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()
      ..isTreeBuilding = false
      ..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    // Verify the "Tree is Closed" message is wrapped in a [Tooltip].
    final Finder tooltipFinder = find.byWidgetPredicate((Widget widget) {
      return widget is Tooltip && (widget.message?.contains('Tree is Closed') ?? false);
    });
    expect(tooltipFinder, findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.red[800]);
    expect(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('shows tree open when fetch tree status is true', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()
      ..isTreeBuilding = true
      ..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Tree is Open'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.green);
    expect(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('shows tree open when fetch tree status is true, dark mode', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()
      ..isTreeBuilding = true
      ..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Tree is Open'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.green[800]);
    expect(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('show error snackbar when error occurs', (WidgetTester tester) async {
    configureView(tester.view);
    String? lastError;
    final FakeBuildState buildState = FakeBuildState()
      ..errors.addListener((String message) => lastError = message)
      ..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: buildState,
          child: ValueProvider<GoogleSignInService>(
            value: buildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(lastError, isNull);

    // propagate the error message
    await checkOutput(
      block: () async {
        buildState.errors.send('ERROR');
      },
      output: <String>[
        'ERROR',
      ],
    );
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 750)); // open animation for snackbar

    expect(find.text(lastError!), findsOneWidget);

    // Snackbar message should go away after its duration
    await tester.pump(ErrorBrookWatcher.errorSnackbarDuration); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(lastError!), findsNothing);
  });

  testWidgets('TaskGridContainer with default Settings property sheet', (WidgetTester tester) async {
    configureView(tester.view);
    await precacheTaskIcons(tester);
    final BuildState buildState = BuildState(
      cocoonService: DevelopmentCocoonService(DateTime.utc(2020)),
      authService: fakeAuthService,
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: buildState,
          child: ValueProvider<GoogleSignInService>(
            value: buildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    await expectGoldenMatches(find.byType(BuildDashboardPage), 'build_dashboard.defaultPropertySheet.png');
    expect(tester, meetsGuideline(textContrastGuideline));

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('TaskGridContainer with default Settings property sheet, dark mode', (WidgetTester tester) async {
    configureView(tester.view);
    await precacheTaskIcons(tester);
    final BuildState buildState = BuildState(
      cocoonService: DevelopmentCocoonService(DateTime.utc(2020)),
      authService: fakeAuthService,
    );
    void listener1() {}
    buildState.addListener(listener1);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: buildState,
          child: ValueProvider<GoogleSignInService>(
            value: buildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    await expectGoldenMatches(find.byType(BuildDashboardPage), 'build_dashboard.defaultPropertySheet.dark.png');
    expect(tester, meetsGuideline(textContrastGuideline));

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('ensure smooth transition between invalid states', (WidgetTester tester) async {
    configureView(tester.view);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;
    BuildDashboardPage controlledBuildDashboardPage = const BuildDashboardPage(
      queryParameters: {
        'repo': 'flutter',
        'branch': 'flutter-release',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: controlledBuildDashboardPage,
          ),
        ),
      ),
    );

    expect(find.byType(dropdownButtonType), findsNWidgets(2));
    // simulate a url request, which retriggers a rebuild of the widget
    controlledBuildDashboardPage = const BuildDashboardPage(
      queryParameters: {
        'repo': 'engine',
      },
    );
    expect(
      (tester.widget(find.byKey(const Key('branch dropdown'))) as DropdownButton).value,
      equals('flutter-release'),
    ); //invalid state: engine + flutter-release
    await tester.pump(); //an invalid state will generate delayed network responses

    //if a delayed network request come in, from a previous invalid state: cocoon + engine - release, no exceptions should be raised
    controlledBuildDashboardPage = const BuildDashboardPage(
      queryParameters: {
        'repo': 'cocoon',
        'branch': 'engine-release',
      },
    );
  });

  testWidgets('shows branch and repo dropdown button in settings when screen is small', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final BuildState fakeBuildState = FakeBuildState()..authService = fakeAuthService;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueProvider<BuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.byType(dropdownButtonType), findsNothing);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    expect(find.byType(dropdownButtonType), findsNWidgets(2));
  });
}
