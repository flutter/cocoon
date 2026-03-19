// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
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
  }) {
    _isAuthenticated = authService.isAuthenticated;
    authService.addListener(onAuthChanged);
  }

  /// Cocoon backend service that retrieves the data needed for this state.
  final CocoonService cocoonService;

  /// Authentication service for managing Google Sign In.
  final FirebaseAuthService authService;

  bool _isAuthenticated = false;

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

  /// Set of job names that are currently being re-run.
  Set<String> get rerunningJobs => _rerunningJobs;
  final Set<String> _rerunningJobs = <String>{};

  /// Whether "Re-run failed" is currently in progress.
  bool get isRerunningAll => _isRerunningAll;
  bool _isRerunningAll = false;

  /// The currently selected task statuses for filtering.
  Set<TaskStatus> get selectedStatuses => _selectedStatuses;
  Set<TaskStatus> _selectedStatuses = TaskStatus.values.toSet();

  /// The currently selected platforms for filtering.
  Set<String> get selectedPlatforms => _selectedPlatforms;
  Set<String> _selectedPlatforms = <String>{};

  /// The current job name filter (regex).
  String? get jobNameFilter => _jobNameFilter;
  String? _jobNameFilter;

  /// All unique platforms derived from the current [guardResponse].
  Set<String> get availablePlatforms => _availablePlatforms;
  Set<String> _availablePlatforms = <String>{};

  /// Update the current filters and notify listeners.

  void updateFilters({
    Set<TaskStatus>? statuses,
    Set<String>? platforms,
    String? jobNameFilter,
  }) {
    if (statuses != null) {
      _selectedStatuses = statuses;
    }
    if (platforms != null) {
      _selectedPlatforms = platforms;
    }
    if (jobNameFilter != null) {
      _jobNameFilter = jobNameFilter;
    }
    notifyListeners();
  }

  /// Reset all filters to their default values and notify listeners.
  void clearFilters() {
    _selectedStatuses = TaskStatus.values.toSet();
    _selectedPlatforms = <String>{};
    _availablePlatforms = <String>{};
    _jobNameFilter = null;
    notifyListeners();
  }

  void _updateSelectedPlatforms() {
    final response = _guardResponse;
    if (response == null) {
      _availablePlatforms = {};
      return;
    }

    final newAvailablePlatforms = <String>{};
    for (final stage in response.stages) {
      for (final jobName in stage.builds.keys) {
        newAvailablePlatforms.add(jobName.split(' ').first);
      }
    }

    // If this is the first time we load data for this PR/session, select everything.
    if (_availablePlatforms.isEmpty) {
      _selectedPlatforms = Set.from(newAvailablePlatforms);
    }

    _availablePlatforms = newAvailablePlatforms;
  }

  /// Returns a [PresubmitGuardResponse] filtered by the current filter state.

  ///
  /// If [guardResponse] is null, this returns null.
  PresubmitGuardResponse? get filteredGuardResponse {
    final response = _guardResponse;
    if (response == null) {
      return null;
    }

    final filteredStages = <PresubmitGuardStage>[];
    for (final stage in response.stages) {
      final filteredBuilds = <String, TaskStatus>{};
      for (final entry in stage.builds.entries) {
        final jobName = entry.key;
        final status = entry.value;

        // Status filter
        if (!_selectedStatuses.contains(status)) {
          continue;
        }

        // Platform filter
        final platform = jobName.split(' ').first;
        if (_selectedPlatforms.isNotEmpty &&
            !_selectedPlatforms.contains(platform)) {
          continue;
        }

        // Regex filter
        if (_jobNameFilter != null && _jobNameFilter!.isNotEmpty) {
          try {
            final regex = RegExp(_jobNameFilter!, caseSensitive: false);
            if (!regex.hasMatch(jobName)) {
              continue;
            }
          } catch (e) {
            // Invalid regex, skip filtering by it.
          }
        }

        filteredBuilds[jobName] = status;
      }

      if (filteredBuilds.isNotEmpty) {
        filteredStages.add(
          PresubmitGuardStage(
            name: stage.name,
            createdAt: stage.createdAt,
            builds: filteredBuilds,
          ),
        );
      }
    }

    return PresubmitGuardResponse(
      prNum: response.prNum,
      checkRunId: response.checkRunId,
      author: response.author,
      stages: filteredStages,
      guardStatus: response.guardStatus,
    );
  }

  /// Manually set the guard response for testing purposes.
  @visibleForTesting
  void setGuardResponseForTest(PresubmitGuardResponse response) {
    _guardResponse = response;
    _updateSelectedPlatforms();
    notifyListeners();
  }

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
  Future<void> update({String? repo, String? pr, String? sha}) async {
    if (_syncParameters(repo: repo, pr: pr, sha: sha)) {
      notifyListeners();
    }
    await fetchIfNeeded();
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
      clearFilters();
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
  Future<void> selectCheck(String? name) async {
    if (_selectedCheck == name) {
      return;
    }
    _selectedCheck = name;
    _checks = null;
    notifyListeners();
    if (_selectedCheck != null) {
      await fetchCheckDetails();
    }
  }

  /// Trigger data fetching if parameters were updated but data is missing.
  Future<void> fetchIfNeeded() async {
    if (isLoading) {
      return;
    }
    if (pr == null && sha != null && _lastFetchedSha != sha) {
      await fetchGuardStatus();
    }
    if (pr != null) {
      if (_availableSummaries.isEmpty && _lastFetchedPr != pr) {
        await fetchAvailableShas();
      }
    }

    if (sha != null && _guardResponse == null && _lastFetchedSha != sha) {
      await fetchGuardStatus();
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
    await fetchIfNeeded(); // Proceed to fetch guard status for the new SHA
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
      if (pr == null && sha != null) {
        pr = _guardResponse?.prNum.toString();
      }
      _updateSelectedPlatforms();
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
      repo: repo,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _checks = response.data;
    }
    _isChecksLoading = false;
    notifyListeners();
  }

  bool canRerunFailedJob(String jobName) =>
      authService.isAuthenticated &&
      pr != null &&
      !_rerunningJobs.contains(jobName) &&
      !_isRerunningAll;

  bool get canRerunAllFailedJobs =>
      authService.isAuthenticated && pr != null && !_isRerunningAll;

  /// Schedule the provided [jobName] to be re-run.
  ///
  /// Returns an error message if the request failed, otherwise null.
  Future<String?> rerunFailedJob(String jobName) async {
    if (!canRerunFailedJob(jobName)) {
      return null;
    }

    _rerunningJobs.add(jobName);
    notifyListeners();

    try {
      final idToken = await authService.idToken;
      final response = await cocoonService.rerunFailedJob(
        idToken: idToken,
        repo: repo,
        pr: int.parse(pr!),
        buildName: jobName,
      );

      if (response.error != null) {
        return response.error;
      }

      unawaited(_fetchRefreshUpdate());
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _rerunningJobs.remove(jobName);
      notifyListeners();
    }
  }

  /// Schedule all failed jobs for the current [pr] to be re-run.
  ///
  /// Returns an error message if the request failed, otherwise null.
  Future<String?> rerunAllFailedJobs() async {
    if (!canRerunAllFailedJobs) {
      return null;
    }

    _isRerunningAll = true;
    notifyListeners();

    try {
      final idToken = await authService.idToken;
      final response = await cocoonService.rerunAllFailedJobs(
        idToken: idToken,
        repo: repo,
        pr: int.parse(pr!),
      );

      if (response.error != null) {
        return response.error;
      }

      unawaited(_fetchRefreshUpdate());
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isRerunningAll = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void onAuthChanged() {
    if (!_active) {
      return;
    }
    if (authService.isAuthenticated != _isAuthenticated) {
      // Authentication status changed (login or logout), refresh state
      _fetchRefreshUpdate();
    }
    _isAuthenticated = authService.isAuthenticated;
  }

  @override
  void dispose() {
    _active = false;
    authService.removeListener(onAuthChanged);
    refreshTimer?.cancel();
    super.dispose();
  }
}
