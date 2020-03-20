// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show Commit, CommitStatus, RootKey, Task;

import '../service/cocoon.dart';
import '../service/google_authentication.dart';
import 'brooks.dart';

/// State for the Flutter Build Dashboard
class FlutterBuildState extends ChangeNotifier {
  /// Creates a new [FlutterBuildState].
  ///
  /// If [CocoonService] is not specified, a new [CocoonService] instance is created.
  FlutterBuildState({
    CocoonService cocoonServiceValue,
    GoogleSignInService authServiceValue,
  })  : _cocoonService = cocoonServiceValue ?? CocoonService(),
        authService = authServiceValue ?? GoogleSignInService() {
    authService.notifyListeners = notifyListeners;
  }

  /// Cocoon backend service that retrieves the data needed for this state.
  final CocoonService _cocoonService;

  /// Authentication service for managing Google Sign In.
  GoogleSignInService authService;

  /// How often to query the Cocoon backend for the current build state.
  @visibleForTesting
  final Duration refreshRate = const Duration(seconds: 10);

  /// Timer that calls [_fetchBuildStatusUpdate] on a set interval.
  @visibleForTesting
  Timer refreshTimer;

  /// The current status of the commits loaded.
  List<CommitStatus> _statuses = <CommitStatus>[];
  List<CommitStatus> get statuses => _statuses;

  /// Whether or not flutter/flutter currently passes tests.
  bool _isTreeBuilding;
  bool get isTreeBuilding => _isTreeBuilding;

  /// Git branches from flutter/flutter for managing Flutter releases.
  List<String> _branches = <String>['master'];
  List<String> get branches => _branches;

  /// The current flutter/flutter git branch to show data from.
  String _currentBranch = 'master';
  String get currentBranch => _currentBranch;

  /// Whether more [List<CommitStatus>] can be loaded from Cocoon.
  ///
  /// If [fetchMoreCommitStatuses] returns no data, it is assumed the last
  /// [CommitStatus] has been loaded.
  bool get moreStatusesExist => _moreStatusesExist;
  bool _moreStatusesExist = true;

  /// A [Brook] that reports when errors occur that relate to this [FlutterBuildState].
  Brook<String> get errors => _errors;
  final ErrorSink _errors = ErrorSink();

  @visibleForTesting
  static const String errorMessageFetchingStatuses = 'An error occured fetching build statuses from Cocoon';

  @visibleForTesting
  static const String errorMessageFetchingTreeStatus = 'An error occured fetching tree status from Cocoon';

  @visibleForTesting
  static const String errorMessageFetchingBranches =
      'An error occured fetching branches from flutter/flutter on Cocoon.';

  /// Start a fixed interval loop that fetches build state updates based on [refreshRate].
  Future<void> startFetchingUpdates() async {
    if (refreshTimer != null && refreshTimer.isActive) {
      // There's already an update loop, no need to make another.
      return;
    }

    /// [Timer.periodic] does not necessarily run at the start of the timer.
    _fetchBuildStatusUpdate();

    _fetchFlutterBranches().then((List<String> branchResponse) => _branches = branchResponse);

    refreshTimer = Timer.periodic(refreshRate, (_) => _fetchBuildStatusUpdate());
  }

  /// Update build state to be on [branch] and erase previous branch data.
  Future<void> updateCurrentBranch(String branch) async {
    _currentBranch = branch;
    _moreStatusesExist = true;
    _isTreeBuilding = null;
    _statuses = <CommitStatus>[];

    /// Clear previous branch data from the widgets
    notifyListeners();

    /// To prevent delays, make an immediate request for dashboard data.
    _fetchBuildStatusUpdate();
  }

  /// Request the latest [statuses] and [isTreeBuilding] from [CocoonService].
  ///
  /// If fetched [statuses] is not on the current branch it will be discarded.
  Future<void> _fetchBuildStatusUpdate() async {
    await Future.wait(<Future<void>>[
      _cocoonService.fetchCommitStatuses(branch: _currentBranch).then((CocoonResponse<List<CommitStatus>> response) {
        if (response.error != null) {
          _errors.send('$errorMessageFetchingStatuses: ${response.error}');
        } else {
          _mergeRecentCommitStatusesWithStoredStatuses(response.data);
        }
        notifyListeners();
      }),
      _cocoonService.fetchTreeBuildStatus(branch: _currentBranch).then((CocoonResponse<bool> response) {
        if (response.error != null) {
          _errors.send('$errorMessageFetchingTreeStatus: ${response.error}');
        } else {
          _isTreeBuilding = response.data;
        }
        notifyListeners();
      }),
    ]);
  }

  /// Request the latests [branches] from [CocoonService].
  Future<List<String>> _fetchFlutterBranches() async {
    return _cocoonService.fetchFlutterBranches().then((CocoonResponse<List<String>> response) {
      if (response.error != null) {
        _errors.send('$errorMessageFetchingBranches: ${response.error}');
      }

      return response.data;
    });
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
      // Do not merge statueses if they are not from the current branch.
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
    for (int index = 0; index < statuses.length; index++) {
      final CommitStatus current = _statuses[index];

      if (current.commit.key == statusToFind.commit.key) {
        return index;
      }
    }

    return -1;
  }

  /// When the user reaches the end of [statuses], we load more from Cocoon
  /// to create an infinite scroll effect.
  Future<void> fetchMoreCommitStatuses() async {
    assert(_statuses.isNotEmpty);

    final CocoonResponse<List<CommitStatus>> response = await _cocoonService.fetchCommitStatuses(
      lastCommitStatus: _statuses.last,
      branch: _currentBranch,
    );
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

  Future<void> signIn() => authService.signIn();
  Future<void> signOut() => authService.signOut();

  Future<bool> rerunTask(Task task) async {
    return _cocoonService.rerunTask(task, await authService.idToken);
  }

  Future<bool> downloadLog(Task task, Commit commit) async {
    return _cocoonService.downloadLog(task, await authService.idToken, commit.sha);
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
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
    final Map<RootKey, bool> uniqueStatuses = <RootKey, bool>{};

    for (int i = 0; i < statuses.length; i++) {
      final Commit current = statuses[i].commit;

      if (uniqueStatuses.containsKey(current.key)) {
        return false;
      } else {
        uniqueStatuses[current.key] = true;
      }
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
}
