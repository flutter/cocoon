// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/foundation.dart';

import '../logic/task_sorting.dart';
import '../service/cocoon.dart';
import '../service/firebase_auth.dart';

/// State for the Presubmit Dashboard.
///
/// This state manages the data for a specific Pull Request (PR) or commit SHA,
/// including available SHAs, guard status, and individual check results.
class PresubmitState extends ChangeNotifier {
  PresubmitState({
    required this.cocoonService,
    required this.authService,
    this.pr,
    this.sha,
  }) {
    authService.addListener(onAuthChanged);
    if (pr != null || sha != null) {
      fetchIfNeeded();
    }
  }

  final CocoonService cocoonService;
  final FirebaseAuthService authService;

  /// The repository name (e.g., 'flutter', 'engine').
  String repo = 'flutter';

  /// The pull request number string.
  String? pr;

  /// The commit SHA string.
  String? sha;

  /// Whether data is currently being fetched.
  bool get isLoading =>
      _isSummariesLoading || _isGuardLoading || _isChecksLoading;

  bool _isSummariesLoading = false;
  bool _isGuardLoading = false;
  bool _isChecksLoading = false;

  /// The full guard status response for the current [sha].
  PresubmitGuardResponse? get guardResponse => _guardResponse;
  PresubmitGuardResponse? _guardResponse;

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

  /// Whether any filter is currently applied.
  bool get isAnyFilterApplied {
    return _selectedStatuses.length < TaskStatus.values.length ||
        (_availablePlatforms.isNotEmpty &&
            _selectedPlatforms.length < _availablePlatforms.length) ||
        (_jobNameFilter != null && _jobNameFilter!.isNotEmpty);
  }

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
    _ensureValidSelection();
    notifyListeners();
  }

  /// Reset all filters to their default values and notify listeners.
  void clearFilters() {
    _selectedStatuses = TaskStatus.values.toSet();
    _selectedPlatforms = <String>{};
    _availablePlatforms = <String>{};
    _jobNameFilter = null;
    _ensureValidSelection();
    notifyListeners();
  }

  void _ensureValidSelection() {
    final filtered = filteredGuardResponse;
    if (filtered == null ||
        filtered.stages.isEmpty ||
        filtered.stages.every((s) => s.builds.isEmpty)) {
      _selectedCheck = null;
      _checks = null;
      return;
    }

    // Check if current selection is still visible
    var isVisible = false;
    if (_selectedCheck != null) {
      for (final stage in filtered.stages) {
        if (stage.builds.containsKey(_selectedCheck)) {
          isVisible = true;
          break;
        }
      }
    }

    if (!isVisible) {
      // Select first available check based on UI sorting
      String? topMost;
      for (final stage in filtered.stages) {
        if (stage.builds.isNotEmpty) {
          final sortedBuilds = stage.builds.entries.toList()
            ..sort((a, b) => compareTasks(a.key, a.value, b.key, b.value));
          topMost = sortedBuilds.first.key;
          break;
        }
      }

      _selectedCheck = topMost;
      _checks = null;
      if (_selectedCheck != null) {
        unawaited(fetchCheckDetails());
      }
    }
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
    return filterResponse(_guardResponse);
  }

  /// Filters the given [response] using the current state or provided overrides.
  PresubmitGuardResponse? filterResponse(
    PresubmitGuardResponse? response, {
    Set<TaskStatus>? statuses,
    Set<String>? platforms,
    String? jobNameFilter,
  }) {
    if (response == null) {
      return null;
    }

    final effectiveStatuses = statuses ?? _selectedStatuses;
    final effectivePlatforms = platforms ?? _selectedPlatforms;
    final effectiveJobNameFilter = jobNameFilter ?? _jobNameFilter;

    final filteredStages = <PresubmitGuardStage>[];
    for (final stage in response.stages) {
      final filteredBuilds = <String, TaskStatus>{};
      for (final entry in stage.builds.entries) {
        final jobName = entry.key;
        final status = entry.value;

        // Status filter
        if (!effectiveStatuses.contains(status)) {
          continue;
        }

        // Platform filter
        final platform = jobName.split(' ').first;
        if (effectivePlatforms.isNotEmpty &&
            !effectivePlatforms.contains(platform)) {
          continue;
        }

        // Regex filter
        if (effectiveJobNameFilter != null &&
            effectiveJobNameFilter.isNotEmpty) {
          try {
            final regex = RegExp(effectiveJobNameFilter, caseSensitive: false);
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
    _ensureValidSelection();
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
      refreshTimer?.cancel();
      refreshTimer = null;
    }
  }

  void _startTimer() {
    refreshTimer?.cancel();
    refreshTimer = Timer.periodic(
      refreshRate,
      (Timer t) => _fetchRefreshUpdate(),
    );
  }

  /// Syncs internal state with the provided parameters.
  ///
  /// This is used to initialize or update the state based on URL parameters.
  void syncUpdate({String? repo, String? pr, String? sha}) {
    var changed = false;
    if (repo != null && repo != this.repo) {
      this.repo = repo;
      changed = true;
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
      _lastFetchedSha = null;
      _checks = null;
      _selectedCheck = null;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Explicitly updates parameters and triggers a fetch.
  void update({String? repo, String? pr, String? sha}) {
    syncUpdate(repo: repo, pr: pr, sha: sha);
    fetchIfNeeded();
  }

  /// Triggers a data fetch if parameters have changed.
  void fetchIfNeeded() {
    if (pr != null && _lastFetchedPr != pr) {
      unawaited(fetchAvailableShas());
    }
    if (sha != null && _lastFetchedSha != sha) {
      unawaited(fetchGuardStatus());
    }
  }

  /// Selects a specific check and fetches its details.
  void selectCheck(String buildName) {
    if (_selectedCheck == buildName) return;
    _selectedCheck = buildName;
    _checks = null;
    notifyListeners();
    unawaited(fetchCheckDetails());
  }

  /// Fetches available SHAs for the current [pr].
  Future<void> fetchAvailableShas() async {
    if (pr == null) return;
    _isSummariesLoading = true;
    _lastFetchedPr = pr;
    notifyListeners();

    final response = await cocoonService.fetchPresubmitGuardSummaries(
      pr: pr!,
      repo: repo,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _availableSummaries = response.data ?? [];
      // Default to the latest SHA if none selected
      if (sha == null && _availableSummaries.isNotEmpty) {
        sha = _availableSummaries.first.commitSha;
        unawaited(fetchGuardStatus());
      }
    }
    _isSummariesLoading = false;
    notifyListeners();
  }

  /// Fetches the guard status for the current [sha].
  Future<void> fetchGuardStatus() async {
    if (sha == null) return;
    _isGuardLoading = true;
    _lastFetchedSha = sha;
    notifyListeners();

    final response = await cocoonService.fetchPresubmitGuard(
      sha: sha!,
      repo: repo,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _guardResponse = response.data;
      if (pr == null && sha != null) {
        pr = _guardResponse?.prNum.toString();
      }
      _updateSelectedPlatforms();
      _ensureValidSelection();
    }
    _isGuardLoading = false;
    notifyListeners();
  }

  /// Fetches details/logs for the current [selectedCheck].
  Future<void> fetchCheckDetails() async {
    if (_selectedCheck == null || _guardResponse == null) return;
    _isChecksLoading = true;
    notifyListeners();

    final response = await cocoonService.fetchPresubmitCheckDetails(
      checkRunId: _guardResponse!.checkRunId,
      buildName: _selectedCheck!,
      repo: repo,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _checks = response.data ?? [];
    }
    _isChecksLoading = false;
    notifyListeners();
  }

  /// Schedules a re-run for a failed job.
  Future<String?> rerunFailedJob(String buildName) async {
    if (pr == null) return 'No PR selected';
    _isChecksLoading = true;
    notifyListeners();

    final response = await cocoonService.rerunFailedJob(
      idToken: await authService.idToken,
      repo: repo,
      pr: int.parse(pr!),
      buildName: buildName,
    );

    _isChecksLoading = false;
    if (response.error == null) {
      // Trigger a refresh after a small delay to allow the backend to update
      Timer(const Duration(seconds: 2), () => unawaited(fetchGuardStatus()));
    }
    notifyListeners();
    return response.error;
  }

  /// Schedules a re-run for all failed jobs in the current PR.
  Future<String?> rerunAllFailedJobs() async {
    if (pr == null) return 'No PR selected';
    _isRerunningAll = true;
    notifyListeners();

    final response = await cocoonService.rerunAllFailedJobs(
      idToken: await authService.idToken,
      repo: repo,
      pr: int.parse(pr!),
    );

    _isRerunningAll = false;
    if (response.error == null) {
      // Trigger a refresh after a small delay
      Timer(const Duration(seconds: 2), () => unawaited(fetchGuardStatus()));
    }
    notifyListeners();
    return response.error;
  }

  /// Whether the user can trigger a re-run for a specific job.
  bool canRerunFailedJob(String buildName) {
    if (!authService.isAuthenticated || isLoading || _isRerunningAll)
      return false;
    // Only allow re-run if the job failed
    final stage = _guardResponse?.stages.firstWhere(
      (s) => s.builds.containsKey(buildName),
      orElse: () =>
          const PresubmitGuardStage(name: '', createdAt: 0, builds: {}),
    );
    final status = stage?.builds[buildName];
    return status == TaskStatus.failed || status == TaskStatus.infraFailure;
  }

  /// Whether the user can trigger "Re-run failed" for all jobs.
  bool get canRerunAllFailedJobs {
    if (!authService.isAuthenticated || isLoading || _isRerunningAll)
      return false;
    // Check if there are any failed jobs
    return _guardResponse?.stages.any(
          (s) => s.builds.values.any(
            (status) =>
                status == TaskStatus.failed ||
                status == TaskStatus.infraFailure,
          ),
        ) ??
        false;
  }

  void _fetchRefreshUpdate() {
    if (!_active) return;
    fetchIfNeeded();
    if (_selectedCheck != null) {
      unawaited(fetchCheckDetails());
    }
  }

  void onAuthChanged() {
    if (authService.isAuthenticated) {
      _fetchRefreshUpdate();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _active = false;
    authService.removeListener(onAuthChanged);
    refreshTimer?.cancel();
    super.dispose();
  }
}
