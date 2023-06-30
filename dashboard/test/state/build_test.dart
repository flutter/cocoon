// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_app_icons/flutter_app_icons_platform_interface.dart';
import 'package:flutter_dashboard/model/branch.pb.dart';
import 'package:flutter_dashboard/model/build_status_response.pb.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/commit_status.pb.dart';
import 'package:flutter_dashboard/model/key.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/service/google_authentication.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_flutter_app_icons.dart';
import '../utils/mocks.dart';
import '../utils/output.dart';

void main() {
  const String defaultBranch = 'master';

  group('BuildState', () {
    late MockCocoonService mockCocoonService;
    late CommitStatus setupCommitStatus;

    setUp(() {
      mockCocoonService = MockCocoonService();
      setupCommitStatus = _createCommitStatus('setup');

      when(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')))
          .thenAnswer((dynamic _) async => CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[setupCommitStatus]));
      when(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch'), repo: anyNamed('repo'))).thenAnswer(
        (_) async =>
            CocoonResponse<BuildStatusResponse>.data(BuildStatusResponse()..buildStatus = EnumBuildStatus.success),
      );
      when(mockCocoonService.fetchRepos())
          .thenAnswer((_) async => const CocoonResponse<List<String>>.data(<String>['flutter']));
      when(mockCocoonService.fetchFlutterBranches()).thenAnswer(
        (_) async => CocoonResponse<List<Branch>>.data(<Branch>[
          Branch()
            ..branch = defaultBranch
            ..repository = 'flutter',
        ]),
      );

      FlutterAppIconsPlatform.instance = FakeFlutterAppIcons();
    });

    tearDown(() {
      clearInteractions(mockCocoonService);
    });

    testWidgets('start calls fetch branches', (WidgetTester tester) async {
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

      // startFetching immediately starts fetching results
      verify(await mockCocoonService.fetchFlutterBranches()).called(1);

      buildState.dispose();
    });

    testWidgets('timer should periodically fetch updates', (WidgetTester tester) async {
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')));

      void listener() {}
      buildState.addListener(listener);

      // startFetching immediately starts fetching results
      verify(await mockCocoonService.fetchCommitStatuses(branch: defaultBranch, repo: 'flutter')).called(1);

      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')));
      await tester.pump(buildState.refreshRate! * 2);
      verify(await mockCocoonService.fetchCommitStatuses(branch: defaultBranch, repo: 'flutter')).called(2);

      buildState.dispose();
    });

    testWidgets('updateCurrentRepoBranch should make old updates stale', (WidgetTester tester) async {
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );

      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')));
      expect(buildState.statuses, isEmpty);

      void listener() {}
      // This invokes startFetchUpdates
      buildState.addListener(listener);

      // startFetching immediately starts fetching results (and returns fake data)
      verify(await mockCocoonService.fetchCommitStatuses(branch: defaultBranch, repo: 'flutter')).called(1);
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: 'main', repo: 'cocoon'));
      expect(buildState.statuses, isNotEmpty);
      // Start another Timer.periodic async call
      await tester.pump();
      // Change the repo to Cocoon while a timer is set, and Cocoon is not expected to return data
      buildState.updateCurrentRepoBranch('cocoon', 'main');
      expect(buildState.statuses, isEmpty);
      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: defaultBranch, repo: 'flutter'));
      expect(buildState.statuses, isEmpty);

      buildState.dispose();
    });

    test('multiple start updates should not change the timer', () {
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener1() {}
      buildState.addListener(listener1);

      // Another listener shouldn't change the timer.
      final Timer? refreshTimer = buildState.refreshTimer;
      void listener2() {}
      buildState.addListener(listener2);
      expect(buildState.refreshTimer, equals(refreshTimer));

      // Removing a listener shouldn't change the timer.
      buildState.removeListener(listener1);
      expect(buildState.refreshTimer, equals(refreshTimer));

      // Removing both listeners should cancel the timer.
      buildState.removeListener(listener2);
      expect(buildState.refreshTimer, isNull);

      // A new listener now should change the timer.
      buildState.addListener(listener1);
      expect(buildState.refreshTimer, isNot(isNull));
      expect(buildState.refreshTimer, isNot(equals(refreshTimer)));
    });

    testWidgets('statuses error should not delete previous statuses data', (WidgetTester tester) async {
      String? lastError;
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      )..errors.addListener((String message) => lastError = message);
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch'), repo: anyNamed('repo')));
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')));
      void listener() {}
      buildState.addListener(listener);
      verify(mockCocoonService.fetchTreeBuildStatus(branch: defaultBranch, repo: 'flutter')).called(1);
      verify(mockCocoonService.fetchCommitStatuses(branch: defaultBranch, repo: 'flutter')).called(1);
      await tester.pump();
      final List<CommitStatus> originalData = buildState.statuses;
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch'), repo: anyNamed('repo')));
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')));

      when(mockCocoonService.fetchCommitStatuses(branch: defaultBranch, repo: 'flutter')).thenAnswer(
        (_) =>
            Future<CocoonResponse<List<CommitStatus>>>.value(const CocoonResponse<List<CommitStatus>>.error('error')),
      );
      await checkOutput(
        block: () async {
          await tester.pump(buildState.refreshRate);
        },
        output: <String>[
          'An error occurred fetching build statuses from Cocoon: error',
        ],
      );
      verify(await mockCocoonService.fetchTreeBuildStatus(branch: defaultBranch, repo: 'flutter')).called(1);
      verify(await mockCocoonService.fetchCommitStatuses(branch: defaultBranch, repo: 'flutter')).called(1);

      expect(buildState.statuses, originalData);
      expect(lastError, startsWith(BuildState.errorMessageFetchingStatuses));

      buildState.dispose();
    });

    testWidgets('build status error should not delete previous build status data', (WidgetTester tester) async {
      String? lastError;
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      )..errors.addListener((String message) => lastError = message);
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch'), repo: anyNamed('repo')));
      void listener() {}
      buildState.addListener(listener);

      await tester.pump();
      verify(mockCocoonService.fetchTreeBuildStatus(branch: defaultBranch, repo: 'flutter')).called(1);
      final bool? originalData = buildState.isTreeBuilding;
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch'), repo: anyNamed('repo')));
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: defaultBranch, repo: 'flutter'));

      when(mockCocoonService.fetchTreeBuildStatus(branch: defaultBranch, repo: 'flutter')).thenAnswer(
        (_) =>
            Future<CocoonResponse<BuildStatusResponse>>.value(const CocoonResponse<BuildStatusResponse>.error('error')),
      );
      await checkOutput(
        block: () async {
          await tester.pump(buildState.refreshRate);
        },
        output: <String>[
          'An error occurred fetching tree status from Cocoon: error',
        ],
      );
      verify(await mockCocoonService.fetchTreeBuildStatus(branch: defaultBranch, repo: 'flutter')).called(1);

      expect(buildState.isTreeBuilding, originalData);
      expect(lastError, startsWith(BuildState.errorMessageFetchingTreeStatus));

      buildState.dispose();
    });

    testWidgets('fetch more commit statuses appends', (WidgetTester tester) async {
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')));

      expect(buildState.statuses, <CommitStatus?>[setupCommitStatus]);

      final CommitStatus statusA = _createCommitStatus('A');
      when(
        mockCocoonService.fetchCommitStatuses(
          lastCommitStatus: captureThat(isNotNull, named: 'lastCommitStatus'),
          branch: anyNamed('branch'),
          repo: anyNamed('repo'),
        ),
      ).thenAnswer((_) async => CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[statusA]));

      await buildState.fetchMoreCommitStatuses();

      expect(buildState.statuses, <CommitStatus?>[setupCommitStatus, statusA]);

      await tester.pump(buildState.refreshRate);

      expect(buildState.statuses, <CommitStatus?>[setupCommitStatus, statusA]);
      expect(buildState.moreStatusesExist, true);

      buildState.dispose();
    });

    testWidgets('fetchMoreCommitStatuses returns empty stops fetching more', (WidgetTester tester) async {
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')));

      expect(buildState.statuses, <CommitStatus?>[setupCommitStatus]);

      when(
        mockCocoonService.fetchCommitStatuses(
          lastCommitStatus: captureThat(isNotNull, named: 'lastCommitStatus'),
          branch: anyNamed('branch'),
          repo: anyNamed('repo'),
        ),
      ).thenAnswer((_) async => const CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[]));

      await buildState.fetchMoreCommitStatuses();

      expect(buildState.statuses, <CommitStatus?>[setupCommitStatus]);
      expect(buildState.moreStatusesExist, false);

      buildState.dispose();
    });

    testWidgets('update branch resets build state data', (WidgetTester tester) async {
      // Only return statuses when on master branch
      when(
        mockCocoonService.fetchCommitStatuses(branch: 'master', repo: 'flutter'),
      ).thenAnswer(
        (_) => Future<CocoonResponse<List<CommitStatus>>>.value(
          CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[setupCommitStatus]),
        ).then((CocoonResponse<List<CommitStatus>> value) => value),
      );
      // Mark tree green on master, red on dev
      when(mockCocoonService.fetchTreeBuildStatus(branch: 'master', repo: 'flutter')).thenAnswer(
        (_) => Future<CocoonResponse<BuildStatusResponse>>.value(
          CocoonResponse<BuildStatusResponse>.data(BuildStatusResponse()..buildStatus = EnumBuildStatus.success),
        ),
      );
      when(mockCocoonService.fetchTreeBuildStatus(branch: 'dev', repo: 'flutter')).thenAnswer(
        (_) => Future<CocoonResponse<BuildStatusResponse>>.value(
          CocoonResponse<BuildStatusResponse>.data(
            BuildStatusResponse()
              ..buildStatus = EnumBuildStatus.failure
              ..failingTasks.addAll(<String>['failing_task_1']),
          ),
        ),
      );
      final BuildState buildState = BuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: 'master', repo: 'flutter'));
      expect(buildState.statuses, isNotEmpty);
      expect(buildState.isTreeBuilding, isNotNull);

      // With mockito, the fetch requests for data will finish immediately
      buildState.updateCurrentRepoBranch('flutter', 'dev');
      await tester.pump();

      expect(buildState.statuses, isEmpty);
      expect(buildState.isTreeBuilding, false);
      expect(buildState.moreStatusesExist, true);

      buildState.dispose();
    });
  });

  group('refreshGitHubCommits', () {
    late MockCocoonService cocoonService;
    late MockGoogleSignInService authService;

    setUp(() {
      cocoonService = MockCocoonService();
      authService = MockGoogleSignInService();
    });

    testWidgets('fails fast when !isAuthenticated', (_) async {
      when(authService.isAuthenticated).thenReturn(false);

      final BuildState buildState = BuildState(
        authService: authService,
        cocoonService: cocoonService,
      );

      final bool result = await buildState.refreshGitHubCommits();

      expect(result, isFalse);
      verifyNever(cocoonService.vacuumGitHubCommits(any));
    });

    testWidgets('clears user when vacuumGitHubCommits fails', (_) async {
      const String idToken = 'id_token';
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.idToken).thenAnswer((_) async => idToken);
      when(cocoonService.vacuumGitHubCommits(idToken)).thenAnswer((_) async => false);

      final BuildState buildState = BuildState(
        authService: authService,
        cocoonService: cocoonService,
      );

      final bool result = await buildState.refreshGitHubCommits();

      expect(result, isFalse);
      verify(authService.clearUser()).called(1);
    });

    testWidgets('returns true when vacuumGitHubCommits succeeds', (_) async {
      const String idToken = 'id_token';
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.idToken).thenAnswer((_) async => idToken);
      when(cocoonService.vacuumGitHubCommits(idToken)).thenAnswer((_) async => true);

      final BuildState buildState = BuildState(
        authService: authService,
        cocoonService: cocoonService,
      );

      final bool result = await buildState.refreshGitHubCommits();

      expect(result, isTrue);
      verifyNever(authService.clearUser());
    });
  });

  group('rerunTask', () {
    late MockCocoonService cocoonService;
    late MockGoogleSignInService authService;
    final Task task = Task();

    setUp(() {
      cocoonService = MockCocoonService();
      authService = MockGoogleSignInService();
    });

    testWidgets('fails fast when !isAuthenticated', (_) async {
      when(authService.isAuthenticated).thenReturn(false);

      final BuildState buildState = BuildState(
        authService: authService,
        cocoonService: cocoonService,
      );

      final bool result = await buildState.rerunTask(task);

      expect(result, isFalse);
      verifyNever(cocoonService.rerunTask(any, any, any));
    });

    testWidgets('clears user when rerunTask fails', (_) async {
      const String idToken = 'id_token';
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.idToken).thenAnswer((_) async => idToken);
      when(cocoonService.rerunTask(task, idToken, any))
          .thenAnswer((_) async => const CocoonResponse<bool>.error('failed!'));

      final BuildState buildState = BuildState(
        authService: authService,
        cocoonService: cocoonService,
      );

      final bool result = await buildState.rerunTask(task);

      expect(result, isFalse);
      verify(authService.clearUser()).called(1);
    });

    testWidgets('returns true when rerunTask succeeds', (_) async {
      const String idToken = 'id_token';
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.idToken).thenAnswer((_) async => idToken);
      when(cocoonService.rerunTask(task, idToken, any)).thenAnswer((_) async => const CocoonResponse<bool>.data(true));

      final BuildState buildState = BuildState(
        authService: authService,
        cocoonService: cocoonService,
      );

      final bool result = await buildState.rerunTask(task);

      expect(result, isTrue);
      verifyNever(authService.clearUser());
    });
  });

  testWidgets('sign in functions call notify listener', (WidgetTester tester) async {
    final MockGoogleSignIn mockSignInPlugin = MockGoogleSignIn();
    when(mockSignInPlugin.signIn()).thenAnswer((_) => Future<GoogleSignInAccount?>.value(null));
    when(mockSignInPlugin.signOut()).thenAnswer((_) => Future<GoogleSignInAccount?>.value(null));
    when(mockSignInPlugin.signInSilently()).thenAnswer((_) => Future<GoogleSignInAccount?>.value(null));
    when(mockSignInPlugin.onCurrentUserChanged).thenAnswer((_) => Stream<GoogleSignInAccount?>.value(null));
    final MockCocoonService mockCocoonService = MockCocoonService();
    when(mockCocoonService.fetchFlutterBranches()).thenAnswer((_) => Completer<CocoonResponse<List<Branch>>>().future);
    when(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'), repo: anyNamed('repo')))
        .thenAnswer((_) => Completer<CocoonResponse<List<CommitStatus>>>().future);
    when(mockCocoonService.fetchRepos()).thenAnswer((_) => Completer<CocoonResponse<List<String>>>().future);
    when(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch'), repo: anyNamed('repo')))
        .thenAnswer((_) => Completer<CocoonResponse<BuildStatusResponse>>().future);
    final GoogleSignInService signInService = GoogleSignInService(googleSignIn: mockSignInPlugin);
    final BuildState buildState = BuildState(
      cocoonService: mockCocoonService,
      authService: signInService, // TODO(ianh): Settle on one of these two for the whole codebase.
    );

    int callCount = 0;
    buildState.addListener(() => callCount += 1);

    await tester.pump(const Duration(seconds: 5));
    expect(callCount, 1);

    await signInService.signIn();
    expect(callCount, 2);

    await signInService.signOut();
    expect(callCount, 3);

    buildState.dispose();
  });
}

CommitStatus _createCommitStatus(
  String keyValue, {
  String branch = 'master',
  String repo = 'flutter',
}) {
  return CommitStatus()
    ..branch = branch
    ..commit = (Commit()
      // Author is set so we don't have to dig through all the nested fields
      // while debugging
      ..author = keyValue
      ..repository = 'flutter/$repo'
      ..key = (RootKey()..child = (Key()..name = keyValue)));
}
