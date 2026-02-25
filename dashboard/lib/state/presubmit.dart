// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/foundation.dart';

import '../service/cocoon.dart';
import '../service/firebase_auth.dart';

/// State for the PreSubmit View.
class PresubmitState extends ChangeNotifier {
  PresubmitState({
    required this.cocoonService,
    required this.authService,
    this.repo = 'flutter',
    this.pr,
    this.sha,
  });

  /// Cocoon backend service that retrieves the data needed for this state.
  final CocoonService cocoonService;

  /// Authentication service for managing Google Sign In.
  final FirebaseAuthService authService;

  /// The current repo to show data from.
  String repo;

  /// The current PR number.
  String? pr;

  /// The current commit SHA.
  String? sha;

  /// The guard response for the current [sha].
  PresubmitGuardResponse? get guardResponse => _guardResponse;
  PresubmitGuardResponse? _guardResponse;

  /// Whether data is currently being fetched.
  bool get isLoading =>
      _isSummariesLoading || _isGuardLoading || _isChecksLoading;

  bool _isSummariesLoading = false;
  bool _isGuardLoading = false;
  bool _isChecksLoading = false;

  /// The available SHAs for the current [pr].
  List<PresubmitGuardSummary> get availableSummaries => _availableSummaries;
  List<PresubmitGuardSummary> _availableSummaries = [];

  /// The currently selected check name.
  String? get selectedCheck => _selectedCheck;
  String? _selectedCheck;

  /// The checks/logs for the current [selectedCheck].
  List<PresubmitCheckResponse>? get checks => _checks;
  List<PresubmitCheckResponse>? _checks;

  /// Track if we have already attempted to fetch summaries for the current [pr].
  String? _lastFetchedPr;

  /// Track if we have already attempted to fetch guard status for the current [sha].
  String? _lastFetchedSha;

  /// How often to query the Cocoon backend for updates.
  @visibleForTesting
  final Duration refreshRate = const Duration(seconds: 30);

  /// Timer that calls [_fetchRefreshUpdate] on a set interval.
  @visibleForTesting
  Timer? refreshTimer;

  bool _active = true;

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      _startTimer();
      assert(refreshTimer != null);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _stopTimer();
    }
  }

  void _startTimer() {
    refreshTimer?.cancel();
    refreshTimer = Timer.periodic(refreshRate, _fetchRefreshUpdate);
  }

  void _stopTimer() {
    refreshTimer?.cancel();
    refreshTimer = null;
  }

  Future<void> _fetchRefreshUpdate([Timer? timer]) async {
    if (!_active || isLoading) {
      return;
    }

    final refreshes = <Future<void>>[];

    if (pr != null) {
      refreshes.add(fetchAvailableShas(refresh: true));
    } else {
      refreshes.add(fetchRecentCommits(refresh: true));
    }

    if (sha != null) {
      // final isInProgress =
      //     _availableSummaries.first.guardStatus == GuardStatus.inProgress;

      // if (isInProgress) {
      refreshes.add(fetchGuardStatus(refresh: true));
      if (selectedCheck != null) {
        refreshes.add(fetchCheckDetails(refresh: true));
      }
      // }
    }

    if (refreshes.isNotEmpty) {
      await Future.wait(refreshes);
    }
  }

  /// Update the current parameters and trigger fetches if needed.
  void update({String? repo, String? pr, String? sha}) {
    if (_syncParameters(repo: repo, pr: pr, sha: sha)) {
      notifyListeners();
    }
    fetchIfNeeded();
  }

  /// Synchronously update parameters without notifying.
  ///
  /// Returns true if anything changed.
  bool _syncParameters({String? repo, String? pr, String? sha}) {
    var changed = false;
    if (repo != null && this.repo != repo) {
      this.repo = repo;
      changed = true;
      _availableSummaries = [];
      _lastFetchedPr = null;
    }
    if (pr != this.pr) {
      this.pr = pr;
      changed = true;
      _availableSummaries = [];
      _lastFetchedPr = null;
    }
    if (sha != this.sha) {
      this.sha = sha;
      changed = true;
      _guardResponse = null;
      _selectedCheck = null;
      _checks = null;
      _lastFetchedSha = null;
    }
    return changed;
  }

  /// Synchronously update state without notifying.
  void syncUpdate({String? repo, String? pr, String? sha}) {
    _syncParameters(repo: repo, pr: pr, sha: sha);
  }

  /// Select a check and fetch its details.
  void selectCheck(String? name) {
    if (_selectedCheck == name) {
      return;
    }
    _selectedCheck = name;
    _checks = null;
    notifyListeners();
    if (_selectedCheck != null) {
      fetchCheckDetails();
    }
  }

  /// Trigger data fetching if parameters were updated but data is missing.
  void fetchIfNeeded() {
    if (isLoading) {
      return;
    }
    if (pr != null) {
      if (_availableSummaries.isEmpty && _lastFetchedPr != pr) {
        fetchAvailableShas();
      }
    } else {
      if (_availableSummaries.isEmpty && _lastFetchedPr != 'NO_PR') {
        fetchRecentCommits();
      }
    }

    if (sha != null && _guardResponse == null && _lastFetchedSha != sha) {
      fetchGuardStatus();
    }
  }

  /// Request the latest available SHAs for the current [pr] from [CocoonService].
  Future<void> fetchAvailableShas({bool refresh = false}) async {
    if (pr == null || _isSummariesLoading) {
      return;
    }
    _isSummariesLoading = true;
    _lastFetchedPr = pr;
    notifyListeners();

    final response = await cocoonService.fetchPresubmitGuardSummaries(
      repo: repo,
      pr: pr!,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _availableSummaries = response.data!;
      // If no SHA was specified, default to the latest one
      if (sha == null && _availableSummaries.isNotEmpty) {
        sha = _availableSummaries.first.commitSha;
      }
    }
    _isSummariesLoading = false;
    notifyListeners();
    fetchIfNeeded(); // Proceed to fetch guard status for the new SHA
  }

  /// Request recent commits for the current [repo] from [CocoonService].
  Future<void> fetchRecentCommits({bool refresh = false}) async {
    if (_isSummariesLoading) {
      return;
    }
    _isSummariesLoading = true;
    _lastFetchedPr = 'NO_PR'; // Special value for "no PR"
    if (!refresh) {
      _availableSummaries = [];
    }
    notifyListeners();

    final response = await cocoonService.fetchCommitStatuses(repo: repo);

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _availableSummaries = response.data!.map((s) {
        return PresubmitGuardSummary(
          commitSha: s.commit.sha,
          creationTime: s.commit.timestamp.toInt(),
          guardStatus: GuardStatus.waitingForBackfill,
        );
      }).toList();
    }
    _isSummariesLoading = false;
    notifyListeners();
  }

  /// Request the guard status for the current [sha] from [CocoonService].
  Future<void> fetchGuardStatus({bool refresh = false}) async {
    if (sha == null || _isGuardLoading) {
      return;
    }
    _isGuardLoading = true;
    _lastFetchedSha = sha;
    if (!refresh) {
      _guardResponse = null;
    }
    notifyListeners();

    final response = await cocoonService.fetchPresubmitGuard(
      repo: repo,
      sha: sha!,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _guardResponse = response.data;
    }
    _isGuardLoading = false;
    notifyListeners();
  }

  /// Request check details for the current [selectedCheck] and [guardResponse].
  Future<void> fetchCheckDetails({bool refresh = false}) async {
    if (selectedCheck == null || guardResponse == null || _isChecksLoading) {
      return;
    }

    _isChecksLoading = true;
    if (!refresh) {
      _checks = null;
    }
    notifyListeners();

    final response = await cocoonService.fetchPresubmitCheckDetails(
      checkRunId: guardResponse!.checkRunId,
      buildName: selectedCheck!,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _checks = response.data;
    }
    _isChecksLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _active = false;
    refreshTimer?.cancel();
    super.dispose();
  }
}
