// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

import '../logic/task_sorting.dart';
import '../service/cocoon.dart';
import '../service/firebase_auth.dart';

/// State for the Presubmit Dashboard.
///
/// This state manages the data for a specific Pull Request (PR) or commit SHA,
/// including available SHAs, guard status, and individual job results.
class PresubmitState extends ChangeNotifier {
  PresubmitState({
    required this.cocoonService,
    required this.authService,
    String? pr,
    String? sha,
  }) {
    if (pr != null) _queryParams['pr'] = pr;
    if (sha != null) _queryParams['sha'] = sha;
    authService.addListener(onAuthChanged);
    if (pr != null || sha != null) {
      unawaited(fetchIfNeeded());
    }
  }

  final CocoonService cocoonService;
  final FirebaseAuthService authService;

  final Map<String, String> _queryParams = {};
  Map<String, String> get queryParameters => _queryParams;

  /// The repository name (e.g., 'flutter', 'packages').
  String get repo => _queryParams['repo'] ?? 'flutter';
  set repo(String value) {
    if (repo != value) {
      _queryParams['repo'] = value;
      notifyListeners();
    }
  }

  /// The pull request number string.
  String? get pr => _queryParams['pr'];
  set pr(String? value) {
    if (pr != value) {
      if (value == null) {
        _queryParams.remove('pr');
      } else {
        _queryParams['pr'] = value;
      }
      _availableSummaries = [];
      _lastFetchedPr = null;
      notifyListeners();
    }
  }

  /// The commit SHA string.
  String? get sha => _queryParams['sha'];
  set sha(String? value) {
    if (sha != value) {
      if (value == null) {
        _queryParams.remove('sha');
      } else {
        _queryParams['sha'] = value;
      }
      _guardResponse = null;
      _lastFetchedSha = null;
      _jobs = null;
      _queryParams.remove('job');
      if (value == null) {
        _lastFetchedPr = null;
      }
      notifyListeners();
    }
  }

  /// Whether data is currently being fetched.
  bool get isLoading =>
      _isSummariesLoading || _isGuardLoading || _isJobsLoading;

  bool _isSummariesLoading = false;
  bool _isGuardLoading = false;
  bool _isJobsLoading = false;

  /// The full guard status response for the current [sha].
  PresubmitGuardResponse? get guardResponse => _guardResponse;
  PresubmitGuardResponse? _guardResponse;

  /// Whether "Re-run failed" is currently in progress.
  bool get isRerunningAll => _isRerunningAll;
  bool _isRerunningAll = false;

  /// The currently selected task statuses for filtering.
  Set<TaskStatus> get selectedStatuses {
    final statusesParam = _queryParams['statuses'];
    if (statusesParam == null || statusesParam.isEmpty) {
      return TaskStatus.values.toSet();
    }
    return statusesParam
        .split(',')
        .map((s) => TaskStatus.tryFrom(Uri.decodeComponent(s)))
        .whereType<TaskStatus>()
        .toSet();
  }

  /// The currently selected platforms for filtering.
  Set<String> get selectedPlatforms {
    final platformsParam = _queryParams['platforms'];
    if (platformsParam == null || platformsParam.isEmpty) {
      return _availablePlatforms.toSet();
    }
    return platformsParam
        .split(',')
        .map((p) => Uri.decodeComponent(p))
        .toSet();
  }

  /// The current job name filter (regex).
  String? get jobNameFilter {
    final regexParam = _queryParams['regex'];
    if (regexParam == null || regexParam.isEmpty) return null;
    return Uri.decodeComponent(regexParam);
  }

  String get insufficientPermissionMessage =>
      'User has no write permission to $repo github repo.';

  /// Whether any filter is currently applied.
  bool get isAnyFilterApplied {
    return _queryParams.containsKey('statuses') ||
        _queryParams.containsKey('platforms') ||
        _queryParams.containsKey('regex');
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
      if (statuses.length == TaskStatus.values.length) {
        _queryParams.remove('statuses');
      } else {
        _queryParams['statuses'] = statuses
            .map((s) => Uri.encodeComponent(s.value))
            .join(',');
      }
    }
    if (platforms != null) {
      if (_availablePlatforms.isNotEmpty &&
          platforms.length == _availablePlatforms.length) {
        _queryParams.remove('platforms');
      } else {
        _queryParams['platforms'] = platforms
            .map((p) => Uri.encodeComponent(p))
            .join(',');
      }
    }
    if (jobNameFilter != null) {
      if (jobNameFilter.trim().isEmpty) {
        _queryParams.remove('regex');
      } else {
        _queryParams['regex'] = Uri.encodeComponent(jobNameFilter);
      }
    }
    _ensureValidSelection();
    notifyListeners();
  }

  /// Reset all filters to their default values and notify listeners.
  void clearFilters() {
    _queryParams.remove('statuses');
    _queryParams.remove('platforms');
    _queryParams.remove('regex');
    _ensureValidSelection();
    notifyListeners();
  }

  void _ensureValidSelection() {
    final filtered = filteredGuardResponse;
    if (filtered == null ||
        filtered.stages.isEmpty ||
        filtered.stages.every((s) => s.builds.isEmpty)) {
      _setSelectedJob(null);
      _jobs = null;
      return;
    }

    // Check if current selection is still visible
    var isVisible = false;
    final currentJob = selectedJob;
    if (currentJob != null) {
      for (final stage in filtered.stages) {
        if (stage.builds.containsKey(currentJob)) {
          isVisible = true;
          break;
        }
      }
    }

    if (!isVisible) {
      // Select first available job based on UI sorting
      String? topMost;
      for (final stage in filtered.stages) {
        if (stage.builds.isNotEmpty) {
          final sortedBuilds = stage.builds.entries.toList()
            ..sort((a, b) => compareTasks(a.key, a.value, b.key, b.value));
          topMost = sortedBuilds.first.key;
          break;
        }
      }

      _setSelectedJob(topMost);
      _jobs = null;
      if (topMost != null) {
        unawaited(fetchJobDetails());
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

    final effectiveStatuses = statuses ?? this.selectedStatuses;
    final effectivePlatforms = platforms ?? this.selectedPlatforms;
    final effectiveJobNameFilter = jobNameFilter ?? this.jobNameFilter;

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
    if (pr == null) {
      _queryParams['pr'] = response.prNum.toString();
    }
    _updateSelectedPlatforms();
    _ensureValidSelection();
    notifyListeners();
  }

  /// The available SHAs for the current [pr].
  List<PresubmitGuardSummary> get availableSummaries => _availableSummaries;
  List<PresubmitGuardSummary> _availableSummaries = [];

  /// The currently selected job name.
  String? get selectedJob {
    final jobParam = _queryParams['job'];
    if (jobParam == null || jobParam.isEmpty) return null;
    return Uri.decodeComponent(jobParam);
  }

  void _setSelectedJob(String? jobName) {
    if (jobName == null) {
      _queryParams.remove('job');
    } else {
      _queryParams['job'] = Uri.encodeComponent(jobName);
    }
  }

  /// The jobs/logs for the current [selectedJob].
  List<PresubmitJobResponse>? get jobs => _jobs;
  List<PresubmitJobResponse>? _jobs;

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
  void syncUpdate(Map<String, String> newParams) {
    var changed = false;

    final newRepo = newParams['repo'] ?? 'flutter';
    if (repo != newRepo) {
      _queryParams['repo'] = newRepo;
      changed = true;
    }

    final newPr = newParams['pr'];
    if (pr != newPr) {
      if (newPr == null) {
        _queryParams.remove('pr');
      } else {
        _queryParams['pr'] = newPr;
      }
      changed = true;
      _availableSummaries = [];
      _lastFetchedPr = null;
    }

    final newSha = newParams['sha'];
    if (sha != newSha) {
      if (newSha == null) {
        _queryParams.remove('sha');
      } else {
        _queryParams['sha'] = newSha;
      }
      changed = true;
      _guardResponse = null;
      _lastFetchedSha = null;
      _jobs = null;
      _queryParams.remove('job');
      if (newSha == null) {
        _lastFetchedPr = null;
      }
    }

    final newJob = newParams['job'];
    if (newJob != _queryParams['job']) {
      if (newJob == null) {
        _queryParams.remove('job');
      } else {
        _queryParams['job'] = newJob;
      }
      _jobs = null;
      changed = true;
    }

    final newStatuses = newParams['statuses'];
    if (newStatuses != _queryParams['statuses']) {
      if (newStatuses == null) {
        _queryParams.remove('statuses');
      } else {
        _queryParams['statuses'] = newStatuses;
      }
      changed = true;
    }

    final newPlatforms = newParams['platforms'];
    if (newPlatforms != _queryParams['platforms']) {
      if (newPlatforms == null) {
        _queryParams.remove('platforms');
      } else {
        _queryParams['platforms'] = newPlatforms;
      }
      changed = true;
    }

    final newRegex = newParams['regex'];
    if (newRegex != _queryParams['regex']) {
      if (newRegex == null) {
        _queryParams.remove('regex');
      } else {
        _queryParams['regex'] = newRegex;
      }
      changed = true;
    }

    if (changed) {
      _ensureValidSelection();
      notifyListeners();
    }
  }

  /// Explicitly updates parameters and triggers a fetch.
  void update({String? repo, String? pr, String? sha}) {
    final newParams = Map<String, String>.from(_queryParams);
    if (repo != null) newParams['repo'] = repo;
    if (pr != null) {
      newParams['pr'] = pr;
    } else {
      newParams.remove('pr');
    }
    if (sha != null) {
      newParams['sha'] = sha;
    } else {
      newParams.remove('sha');
    }
    syncUpdate(newParams);
    unawaited(fetchIfNeeded());
  }

  /// Triggers a data fetch if parameters have changed.
  Future<void> fetchIfNeeded() async {
    var prFetched = false;
    if (pr != null && _lastFetchedPr != pr) {
      await fetchAvailableShas();
      prFetched = true;
    }
    if (sha != null && _lastFetchedSha != sha) {
      await fetchGuardStatus();
    }
    // We got pr during fetchGuardStatus, so we need to fetch available SHAs.
    if (!prFetched && pr != null) {
      await fetchAvailableShas();
    }
  }

  /// Selects a specific job and fetches its details.
  void selectJob(String jobName) {
    if (selectedJob == jobName) return;
    _setSelectedJob(jobName);
    _jobs = null;
    notifyListeners();
    unawaited(fetchJobDetails());
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
        sha = _availableSummaries.first.headSha;
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

  /// Fetches details/logs for the current [selectedJob].
  Future<void> fetchJobDetails() async {
    if (selectedJob == null || _guardResponse == null) return;
    _isJobsLoading = true;
    notifyListeners();

    final response = await cocoonService.fetchPresubmitJobDetails(
      checkRunId: _guardResponse!.checkRunId,
      jobName: selectedJob!,
      repo: repo,
    );

    if (response.error != null) {
      // TODO: Handle error
    } else {
      _jobs = response.data ?? [];
    }
    _isJobsLoading = false;
    notifyListeners();
  }

  /// Schedules a re-run for a failed job.
  Future<String?> rerunFailedJob(String jobName) async {
    if (pr == null) return 'No PR selected';
    _isJobsLoading = true;
    notifyListeners();

    final response = await cocoonService.rerunFailedJob(
      idToken: await authService.idToken,
      repo: repo,
      pr: int.parse(pr!),
      jobName: jobName,
    );

    if (response.statusCode == 401 && authService.isAuthenticated) {
      return insufficientPermissionMessage;
    }

    _isJobsLoading = false;
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

    if (response.statusCode == 401 && authService.isAuthenticated) {
      return insufficientPermissionMessage;
    }

    _isRerunningAll = false;
    if (response.error == null) {
      // Trigger a refresh after a small delay
      Timer(const Duration(seconds: 2), () => unawaited(fetchGuardStatus()));
    }
    notifyListeners();
    return response.error;
  }

  /// Whether the user can trigger a re-run for a specific job.
  bool canRerunFailedJob(String jobName) {
    if (!authService.isAuthenticated || isLoading || _isRerunningAll) {
      return false;
    }
    // Only allow re-run if the job failed
    final stage = _guardResponse?.stages.firstWhere(
      (s) => s.builds.containsKey(jobName),
      orElse: () =>
          const PresubmitGuardStage(name: '', createdAt: 0, builds: {}),
    );
    final status = stage?.builds[jobName];
    return status == TaskStatus.failed || status == TaskStatus.infraFailure;
  }

  /// Whether the user can trigger "Re-run failed" for all jobs.
  bool get canRerunAllFailedJobs {
    if (!authService.isAuthenticated || isLoading || _isRerunningAll) {
      return false;
    }
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

  /// Whether the user can trigger log analysis for a specific job.
  bool canAnalyzeLog(PresubmitJobResponse job) {
    if (_guardResponse?.enableGeminiLogAnalysis != true) {
      return false;
    }
    if (!authService.isAuthenticated || isLoading) {
      return false;
    }
    if (job.status != TaskStatus.failed &&
        job.status != TaskStatus.infraFailure) {
      return false;
    }
    return job.buildId != null &&
        (job.logAnalysis == null || job.logAnalysis!.trim().isEmpty);
  }

  /// Triggers log analysis for a job.
  Future<String?> analyzeLogs(PresubmitJobResponse job) async {
    if (pr == null) return 'No PR selected';

    final response = await cocoonService.analyzeLogs(
      idToken: await authService.idToken,
      repo: repo,
      pr: int.parse(pr!),
      buildId: Int64.parseInt(job.buildId!),
    );

    if (response.statusCode == 401 && authService.isAuthenticated) {
      return insufficientPermissionMessage;
    }

    return response.error;
  }

  void resume() {
    if (!_active) return;
    _startTimer();
    _fetchRefreshUpdate();
  }

  void pause() {
    refreshTimer?.cancel();
    refreshTimer = null;
  }

  /// Fetches the latest data for the current view.
  ///
  /// This method is called periodically to refresh the data.
  void _fetchRefreshUpdate() {
    if (!_active) return;
    if (pr != null) {
      unawaited(fetchAvailableShas());
    }
    if (sha != null) {
      unawaited(fetchGuardStatus());
    }
    if (selectedJob != null) {
      unawaited(fetchJobDetails());
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
