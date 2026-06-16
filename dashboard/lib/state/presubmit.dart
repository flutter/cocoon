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

const String kFlutterRepo = 'flutter';
const String kNoPRSelectedErrorMessage = 'No PR selected';

enum PresubmitParams implements Comparable<PresubmitParams> {
  repo('repo'),
  pr('pr'),
  sha('sha'),
  job('job'),
  statuses('statuses'),
  platforms('platforms'),
  regex('regex');

  const PresubmitParams(this.value);

  final String value;

  @override
  int compareTo(PresubmitParams other) => index - other.index;

  @override
  String toString() => value;
}

/// State for the Presubmit Dashboard.
///
/// This state manages the data for a specific Pull Request (PR) or commit SHA,
/// including available SHAs, guard status, and individual job results.
class PresubmitState extends ChangeNotifier {
  PresubmitState({required this.cocoonService, required this.authService}) {
    authService.addListener(onAuthChanged);
  }

  final CocoonService cocoonService;
  final FirebaseAuthService authService;

  String get insufficientPermissionMessage =>
      'User has no write permission to $repo github repo.';

  /// The currently selected repository.
  String _repo = kFlutterRepo;
  String get repo => _repo;
  set repo(String value) {
    if (_repo != value) {
      _repo = value;
      notifyListeners();
    }
  }

  /// Track if we have already attempted to fetch summaries for the current [pr].
  String? _lastFetchedPr;

  /// The currently selected pull request number.
  String? _pr;
  String? get pr => _pr;
  set pr(String? value) {
    if (_pr != value) {
      _pr = value;
      _availableSummaries = [];
      _lastFetchedPr = null;
      notifyListeners();
    }
  }

  /// Track if we have already attempted to fetch guard status for the current [sha].
  String? _lastFetchedSha;

  /// The currently selected commit SHA.
  String? _sha;
  String? get sha => _sha;
  set sha(String? value) {
    if (_sha != value) {
      _sha = value;
      _guardResponse = null;
      _lastFetchedSha = null;
      _jobs = null;
      _selectedJob = null;
      if (value == null) {
        _lastFetchedPr = null;
      }
      notifyListeners();
    }
  }

  /// The currently selected job name.
  String? _selectedJob;
  String? get selectedJob => _selectedJob;

  /// The jobs/logs for the current [selectedJob].
  List<PresubmitJobResponse>? get jobs => _jobs;
  List<PresubmitJobResponse>? _jobs;

  /// The full guard status response for the current [sha].
  PresubmitGuardResponse? _guardResponse;
  PresubmitGuardResponse? get guardResponse => _guardResponse;

  /// The available SHAs for the current [pr].
  List<PresubmitGuardSummary> get availableSummaries => _availableSummaries;
  List<PresubmitGuardSummary> _availableSummaries = [];

  /// Returns a [PresubmitGuardResponse] filtered by the current filter state.
  ///
  /// If [guardResponse] is null, this returns null.
  PresubmitGuardResponse? get filteredGuardResponse {
    return filterResponse(_guardResponse);
  }
  /// Whether "Re-run failed" is currently in progress.
  bool get isRerunningAll => _isRerunningAll;

  /// Whether "Re-run failed" is currently in progress.
  bool _isRerunningAll = false;

  /// The currently selected task statuses for filtering.
  Set<TaskStatus> _selectedStatuses = TaskStatus.values.toSet();
  Set<TaskStatus> get selectedStatuses => _selectedStatuses;

  /// The currently selected platforms for filtering.
  Set<String> _selectedPlatforms = <String>{};
  Set<String> get selectedPlatforms => _selectedPlatforms;

  /// The regex pattern for job name filtering.
  String? _jobNameFilter;
  String? get jobNameFilter => _jobNameFilter;

  /// All unique platforms derived from the current [guardResponse].
  Set<String> _availablePlatforms = <String>{};
  Set<String> get availablePlatforms => _availablePlatforms;

  /// The query parameters for the current state.
  Map<String, String> get queryParameters {
    final params = <String, String>{};
    params['${PresubmitParams.repo}'] = _repo;
    if (_pr != null) params['${PresubmitParams.pr}'] = _pr!;
    if (_sha != null) params['${PresubmitParams.sha}'] = _sha!;
    if (_selectedJob != null) {
      params['${PresubmitParams.job}'] = Uri.encodeComponent(_selectedJob!);
    }
    if (!setEquals(_selectedStatuses, TaskStatus.values.toSet())) {
      params['${PresubmitParams.statuses}'] = _selectedStatuses
          .map((s) => Uri.encodeComponent(s.value))
          .join(',');
    }
    if (_availablePlatforms.isNotEmpty &&
        !setEquals(_selectedPlatforms, _availablePlatforms)) {
      params['${PresubmitParams.platforms}'] = _selectedPlatforms
          .map(Uri.encodeComponent)
          .join(',');
    }
    if (_jobNameFilter != null && _jobNameFilter!.isNotEmpty) {
      params['${PresubmitParams.regex}'] = Uri.encodeComponent(_jobNameFilter!);
    }
    return params;
  }

  /// How often to query the Cocoon backend for updates.
  @visibleForTesting
  final Duration refreshRate = const Duration(minutes: 1);

  /// Timer that calls [_fetchRefreshUpdate] on a set interval.
  @visibleForTesting
  Timer? refreshTimer;

  /// Whether the service is active.
  bool _active = true;

  /// Whether data is currently being fetched.
  bool get isLoading =>
      _isSummariesLoading || _isGuardLoading || _isJobsLoading;

  /// Whether summaries are currently being fetched.
  bool _isSummariesLoading = false;

  /// Whether guard status is currently being fetched.
  bool _isGuardLoading = false;

  /// Whether jobs are currently being fetched.
  bool _isJobsLoading = false;

  /// Whether any filter is currently applied.
  bool get isAnyFilterApplied {
    return _selectedStatuses.length < TaskStatus.values.length ||
        (_availablePlatforms.isNotEmpty &&
            _selectedPlatforms.length < _availablePlatforms.length) ||
        (_jobNameFilter != null && _jobNameFilter!.isNotEmpty);
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
    if (_availablePlatforms.isNotEmpty) {
      _selectedPlatforms = Set.from(_availablePlatforms);
    } else {
      _selectedPlatforms = <String>{};
    }
    _jobNameFilter = null;
    _ensureValidSelection();
    notifyListeners();
  }

  /// Ensure that the selected filters are valid.
  void _ensureValidSelection() {
    final filtered = filteredGuardResponse;
    if (filtered == null ||
        filtered.stages.isEmpty ||
        filtered.stages.every((s) => s.builds.isEmpty)) {
      _selectedJob = null;
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

      _selectedJob = topMost;
      _jobs = null;
      if (topMost != null) {
        unawaited(fetchJobDetails());
      }
    }
  }

  /// Update the list of available platforms based on the current [guardResponse].
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

    if (_availablePlatforms.isEmpty ||
        _selectedPlatforms.isEmpty ||
        setEquals(_selectedPlatforms, _availablePlatforms)) {
      _selectedPlatforms = Set.from(newAvailablePlatforms);
    }

    _availablePlatforms = newAvailablePlatforms;
  }

  /// Filters the given [response] using the current state or provided overrides.
  PresubmitGuardResponse? filterResponse(
    PresubmitGuardResponse? response, {
    Set<TaskStatus>? statuses,
    Set<String>? platforms,
    String? filter,
  }) {
    if (response == null) {
      return null;
    }

    final effectiveStatuses = statuses ?? selectedStatuses;
    final effectivePlatforms = platforms ?? selectedPlatforms;
    final effectiveFilter = filter ?? jobNameFilter;

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
        if (effectiveFilter != null && effectiveFilter.isNotEmpty) {
          try {
            final regex = RegExp(effectiveFilter, caseSensitive: false);
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
    _pr ??= response.prNum.toString();
    _updateSelectedPlatforms();
    _ensureValidSelection();
    notifyListeners();
  }

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

    final newRepo = newParams['${PresubmitParams.repo}'] ?? kFlutterRepo;
    if (_repo != newRepo) {
      _repo = newRepo;
      changed = true;
    }

    final newPr = newParams['${PresubmitParams.pr}'];
    if (_pr != newPr) {
      _pr = newPr;
      changed = true;
      _availableSummaries = [];
      _lastFetchedPr = null;
    }

    final newSha = newParams['${PresubmitParams.sha}'];
    if (_sha != newSha) {
      _sha = newSha;
      changed = true;
      _guardResponse = null;
      _lastFetchedSha = null;
      _jobs = null;
      _selectedJob = null;
      if (newSha == null) {
        _lastFetchedPr = null;
      }
    }

    final newJobParam = newParams['${PresubmitParams.job}'];
    final newJob = newJobParam != null
        ? Uri.decodeComponent(newJobParam)
        : null;
    if (_selectedJob != newJob) {
      _selectedJob = newJob;
      _jobs = null;
      changed = true;
    }

    final newStatusesParam = newParams['${PresubmitParams.statuses}'];
    final newStatuses = newStatusesParam != null && newStatusesParam.isNotEmpty
        ? newStatusesParam
              .split(',')
              .map((s) => TaskStatus.tryFrom(Uri.decodeComponent(s)))
              .whereType<TaskStatus>()
              .toSet()
        : TaskStatus.values.toSet();
    if (!setEquals(_selectedStatuses, newStatuses)) {
      _selectedStatuses = newStatuses;
      changed = true;
    }

    final newPlatformsParam = newParams['${PresubmitParams.platforms}'];
    final newPlatforms =
        newPlatformsParam != null && newPlatformsParam.isNotEmpty
        ? newPlatformsParam.split(',').map(Uri.decodeComponent).toSet()
        : _availablePlatforms.toSet();
    if (!setEquals(_selectedPlatforms, newPlatforms)) {
      _selectedPlatforms = newPlatforms;
      changed = true;
    }

    final newRegexParam = newParams['${PresubmitParams.regex}'];
    final newRegex = newRegexParam != null && newRegexParam.isNotEmpty
        ? Uri.decodeComponent(newRegexParam)
        : null;
    if (_jobNameFilter != newRegex) {
      _jobNameFilter = newRegex;
      changed = true;
    }

    if (changed) {
      _ensureValidSelection();
      notifyListeners();
    }
  }

  /// Explicitly updates parameters and triggers a fetch.
  void update({String? repo, String? pr, String? sha}) {
    if (repo != null) this.repo = repo;
    if (pr != null) {
      this.pr = pr;
    } else {
      this.pr = null;
    }
    if (sha != null) {
      this.sha = sha;
    } else {
      this.sha = null;
    }
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
    _selectedJob = jobName;
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
    if (pr == null) return kNoPRSelectedErrorMessage;
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
    if (pr == null) return kNoPRSelectedErrorMessage;
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
    if (pr == null) return kNoPRSelectedErrorMessage;

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
