// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic/brooks.dart';
import '../model/build_status_response.pb.dart';
import '../model/commit.pb.dart';
import '../model/commit_status.pb.dart';
import '../model/key.pb.dart';
import '../model/task.pb.dart';
import '../service/cocoon.dart';
import '../service/google_authentication.dart';

/// State for the Flutter Build Dashboard.
class BuildState extends ChangeNotifier {
  BuildState({
    @required this.cocoonService,
    @required this.authService,
  }) {
    authService.addListener(notifyListeners);
  }

  /// Cocoon backend service that retrieves the data needed for this state.
  final CocoonService cocoonService;

  /// Authentication service for managing Google Sign In.
  final GoogleSignInService authService;

  /// Recent branches for flutter related to releases.
  List<String> get branches => _branches;
  List<String> _branches = <String>['master'];

  /// The active flutter branches to show data from.
  String get currentBranch => _currentBranch;
  String _currentBranch = 'master';

  /// The current repo from [repos] to show data from.
  String get currentRepo => _currentRepo;
  String _currentRepo = 'flutter';

  /// Repos in the Flutter organization this dashboard supports.
  List<String> get repos => _repos;
  List<String> _repos = <String>['flutter'];

  /// The current status of the commits loaded.
  List<CommitStatus> get statuses => _statuses;
  List<CommitStatus> _statuses = <CommitStatus>[];

  /// Whether or not flutter/flutter currently passes tests.
  bool get isTreeBuilding => _isTreeBuilding;
  bool _isTreeBuilding;

  List<String> get failingTasks => _failingTasks;
  List<String> _failingTasks = <String>[];

  /// Whether more [List<CommitStatus>] can be loaded from Cocoon.
  ///
  /// If [fetchMoreCommitStatuses] returns no data, it is assumed the last
  /// [CommitStatus] has been loaded.
  bool get moreStatusesExist => _moreStatusesExist;
  bool _moreStatusesExist = true;

  /// A [Brook] that reports when errors occur that relate to this [BuildState].
  Brook<String> get errors => _errors;
  final ErrorSink _errors = ErrorSink();

  @visibleForTesting
  static const String errorMessageFetchingStatuses = 'An error occurred fetching build statuses from Cocoon';

  @visibleForTesting
  static const String errorMessageFetchingTreeStatus = 'An error occurred fetching tree status from Cocoon';

  @visibleForTesting
  static const String errorMessageFetchingFailingTasks =
      'An error occurred fetching the list of failing tasks from Cocoon';

  @visibleForTesting
  static const String errorMessageFetchingBranches =
      'An error occurred fetching branches from flutter/flutter on Cocoon.';

  /// How often to query the Cocoon backend for the current build state.
  @visibleForTesting
  final Duration refreshRate = const Duration(seconds: 30);

  /// Timer that calls [_fetchStatusUpdates] on a set interval.
  @visibleForTesting
  @protected
  Timer refreshTimer;

  // There's no way to cancel futures in the standard library so instead we just track
  // if we've been disposed, and if so, we drop everything on the floor.
  bool _active = true;

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      _startFetchingStatusUpdates();
      assert(refreshTimer != null);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      refreshTimer?.cancel();
      refreshTimer = null;
    }
  }

  /// Start a fixed interval loop that fetches build state updates based on [refreshRate].
  void _startFetchingStatusUpdates() {
    assert(refreshTimer == null);
    _fetchBranches();
    _fetchRepos();
    _fetchStatusUpdates();
    refreshTimer = Timer.periodic(refreshRate, _fetchStatusUpdates);
  }

  /// Request the latest [branches] from [CocoonService].
  Future<void> _fetchBranches() async {
    final CocoonResponse<List<String>> response = await cocoonService.fetchFlutterBranches();

    if (response.error != null) {
      _errors.send('$errorMessageFetchingBranches: ${response.error}');
    } else {
      _branches = response.data;
      notifyListeners();
    }
  }

  /// Request the latest [repos] from [CocoonService].
  Future<void> _fetchRepos() async {
    final CocoonResponse<List<String>> response = await cocoonService.fetchRepos();
    if (response.error != null) {
      _errors.send('$errorMessageFetchingBranches: ${response.error}');
    } else {
      _repos = response.data;
      notifyListeners();
    }
  }

  /// Request the latest [statuses] and [isTreeBuilding] from [CocoonService].
  ///
  /// If fetched [statuses] is not on the current branch it will be discarded.
  Future<void> _fetchStatusUpdates([Timer timer]) async {
    await Future.wait<void>(<Future<void>>[
      () async {
        final CocoonResponse<List<CommitStatus>> response =
            await cocoonService.fetchCommitStatuses(branch: _currentBranch);
        if (!_active) {
          return null;
        }
        if (response.error != null) {
          _errors.send('$errorMessageFetchingStatuses: ${response.error}');
        } else {
          _mergeRecentCommitStatusesWithStoredStatuses(response.data);
          notifyListeners();
        }
      }(),
      () async {
        final CocoonResponse<BuildStatusResponse> response =
            await cocoonService.fetchTreeBuildStatus(branch: _currentBranch);
        if (!_active) {
          return null;
        }
        if (response.error != null) {
          _errors.send('$errorMessageFetchingTreeStatus: ${response.error}');
        } else {
          _isTreeBuilding = response.data.buildStatus == EnumBuildStatus.success;
          _failingTasks = response.data.failingTasks;
          notifyListeners();
        }
      }(),
    ]);
  }

  /// Update build state to be on [branch] and erase previous branch data.
  Future<void> updateCurrentBranch(String branch) {
    if (_currentBranch == branch) {
      // Do nothing if the branch hasn't changed.
      return Future<void>.value();
    }
    _currentBranch = branch;
    _moreStatusesExist = true;
    _isTreeBuilding = null;
    _failingTasks = <String>[];
    _statuses = <CommitStatus>[];

    /// Clear previous branch data from the widgets
    notifyListeners();

    /// To prevent delays, make an immediate request for dashboard data.
    return _fetchStatusUpdates();
  }

  /// Update build state to be on [repo] and erase previous data.
  Future<void> updateCurrentRepo(String repo) {
    if (currentRepo == repo) {
      // Do nothing if the repo hasn't changed.
      return Future<void>.value();
    }
    _currentRepo = repo;
    _moreStatusesExist = true;
    _isTreeBuilding = null;
    _failingTasks = <String>[];
    _statuses = <CommitStatus>[];

    /// Clear previous data from the widgets
    notifyListeners();

    /// To prevent delays, make an immediate request for dashboard data.
    return _fetchStatusUpdates();
  }

  /// Handle merging status updates with the current data in [statuses].
  ///
  /// [recentStatuses] is expected to be sorted from newest commit to oldest
  /// commit. This is the same order as [statuses].
  ///
  /// If the current list of statuses is empty, [recentStatuses] is set
  /// to be the current [statuses].
  ///
  /// Otherwise, follow this algorithm:
  ///   1. Create a new [List<CommitStatus>] that is from [recentStatuses].
  ///   2. Find where [recentStatuses] does not have [CommitStatus] that
  ///      [statuses] has. This is called the [lastKnownIndex].
  ///   3. Append the range of [statuses] from ([lastKnownIndex] to the end of
  ///      statuses) to [recentStatuses]. This is the merged [statuses].
  void _mergeRecentCommitStatusesWithStoredStatuses(
    List<CommitStatus> recentStatuses,
  ) {
    if (!_statusesMatchCurrentBranch(recentStatuses)) {
      // Do not merge statuses if they are not from the current branch.
      // Happens in delayed network requests after switching branches.
      return;
    }

    /// If the current statuses is empty, no merge logic is necessary.
    /// This is used on the first call for statuses.
    if (_statuses.isEmpty) {
      _statuses = recentStatuses;
      return;
    }

    assert(_statusesInOrder(recentStatuses));
    final List<CommitStatus> mergedStatuses = List<CommitStatus>.from(recentStatuses);

    /// Bisect statuses to find the set that doesn't exist in [recentStatuses].
    final CommitStatus lastRecentStatus = recentStatuses.last;
    final int lastKnownIndex = _findCommitStatusIndex(_statuses, lastRecentStatus);

    /// If this assertion error occurs, the Cocoon backend needs to be updated
    /// to return more commit statuses. This error will only occur if there
    /// is a gap between [recentStatuses] and [statuses].
    assert(lastKnownIndex != -1);

    final int firstIndex = lastKnownIndex + 1;
    final int lastIndex = _statuses.length;

    /// If the current statuses has the same statuses as [recentStatuses],
    /// there will be no subset of remaining statuses. Instead, it will give
    /// a list with a null generated [CommitStatus]. Therefore we manually
    /// return an empty list.
    final List<CommitStatus> remainingStatuses = (firstIndex < lastIndex)
        ? _statuses
            .getRange(
              firstIndex,
              lastIndex,
            )
            .toList()
        : <CommitStatus>[];

    mergedStatuses.addAll(remainingStatuses);

    _statuses = mergedStatuses;
    assert(_statusesAreUnique(statuses));
  }

  /// Find the index in [statuses] that has [statusToFind] based on the key.
  /// Return -1 if it does not exist.
  ///
  /// The rest of the data in the [CommitStatus] can be different.
  int _findCommitStatusIndex(
    List<CommitStatus> statuses,
    CommitStatus statusToFind,
  ) {
    for (int index = 0; index < statuses.length; index += 1) {
      final CommitStatus current = _statuses[index];
      if (current.commit.key == statusToFind.commit.key) {
        return index;
      }
    }
    return -1;
  }

  Future<void> _moreStatuses;

  /// When the user reaches the end of [statuses], we load more from Cocoon
  /// to create an infinite scroll effect.
  ///
  /// This method is idempotent (calling it when it's already running will
  /// just return the same Future without kicking off more work).
  Future<void> fetchMoreCommitStatuses() {
    if (_moreStatuses != null) {
      return _moreStatuses;
    }
    _moreStatuses = _fetchMoreCommitStatusesInternal();
    _moreStatuses.whenComplete(() {
      _moreStatuses = null;
    });
    return _moreStatuses;
  }

  Future<void> _fetchMoreCommitStatusesInternal() async {
    assert(_statuses.isNotEmpty);

    final CocoonResponse<List<CommitStatus>> response = await cocoonService.fetchCommitStatuses(
      lastCommitStatus: _statuses.last,
      branch: _currentBranch,
    );
    if (!_active) {
      return;
    }
    if (response.error != null) {
      _errors.send('$errorMessageFetchingStatuses: ${response.error}');
      return;
    }
    final List<CommitStatus> newStatuses = response.data;

    /// Handle the case where release branches only have a few commits.
    if (newStatuses.isEmpty) {
      _moreStatusesExist = false;
      notifyListeners();
      return;
    }

    assert(_statusesInOrder(newStatuses));

    /// The [List<CommitStatus>] returned is the statuses that come at the end
    /// of our current list and can just be appended.
    _statuses.addAll(newStatuses);
    notifyListeners();

    assert(_statusesAreUnique(statuses));
  }

  Future<bool> refreshGitHubCommits() async => cocoonService.vacuumGitHubCommits(await authService.idToken);

  Future<bool> rerunTask(Task task) async {
    return cocoonService.rerunTask(task, await authService.idToken);
  }

  /// Assert that [statuses] is ordered from newest commit to oldest.
  bool _statusesInOrder(List<CommitStatus> statuses) {
    for (int i = 0; i < statuses.length - 1; i++) {
      final Commit current = statuses[i].commit;
      final Commit next = statuses[i + 1].commit;

      if (current.timestamp < next.timestamp) {
        return false;
      }
    }

    return true;
  }

  /// Assert that there are no duplicate commits in [statuses].
  bool _statusesAreUnique(List<CommitStatus> statuses) {
    final Set<RootKey> uniqueStatuses = <RootKey>{};
    for (int i = 0; i < statuses.length; i += 1) {
      final Commit current = statuses[i].commit;
      if (uniqueStatuses.contains(current.key)) {
        return false;
      }
      uniqueStatuses.add(current.key);
    }
    return true;
  }

  /// Check if the latest [List<CommitStatus>] matches the current branch.
  ///
  /// When switching branches, there is potential for the previous branch data
  /// to come in. In that case, the dashboard should ignore that data.
  ///
  /// Returns true if [List<CommitStatus>] is data from the current branch.
  bool _statusesMatchCurrentBranch(List<CommitStatus> statuses) {
    assert(statuses.isNotEmpty);

    final CommitStatus exampleStatus = statuses.first;
    return exampleStatus.branch == _currentBranch;
  }

  @override
  void dispose() {
    authService.removeListener(notifyListeners);
    refreshTimer?.cancel();
    _active = false;
    super.dispose();
  }
}
