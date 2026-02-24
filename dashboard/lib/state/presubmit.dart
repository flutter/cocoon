// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  bool get isLoading => _isLoading;
  bool _isLoading = false;

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
    bool changed = false;
    if (repo != null && this.repo != repo) {
      this.repo = repo;
      changed = true;
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
    if (_isLoading) {
      return;
    }
    if (pr != null && _availableSummaries.isEmpty && _lastFetchedPr != pr) {
      fetchAvailableShas();
    } else if (sha != null && _guardResponse == null && _lastFetchedSha != sha) {
      fetchGuardStatus();
    }
  }

  /// Request the latest available SHAs for the current [pr] from [CocoonService].
  Future<void> fetchAvailableShas() async {
    if (pr == null || _isLoading) {
      return;
    }
    _isLoading = true;
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
    _isLoading = false;
    notifyListeners();
    fetchIfNeeded(); // Proceed to fetch guard status for the new SHA
  }

  /// Request the guard status for the current [sha] from [CocoonService].
  Future<void> fetchGuardStatus() async {
    if (sha == null || _isLoading) {
      return;
    }
    _isLoading = true;
    _lastFetchedSha = sha;
    _guardResponse = null;
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
    _isLoading = false;
    notifyListeners();
  }

  /// Request check details for the current [selectedCheck] and [guardResponse].
  Future<void> fetchCheckDetails() async {
    if (selectedCheck == null || guardResponse == null || _isLoading) {
      return;
    }

    // Handle mock SHAs
    if (sha?.contains('mock_sha') ?? false) {
      _checks = [
        PresubmitCheckResponse(
          attemptNumber: 1,
          buildName: selectedCheck!,
          creationTime: 0,
          status: 'Succeeded',
          summary:
              '[INFO] Starting task $selectedCheck...\n[SUCCESS] Dependencies installed.\n[INFO] Running build script...\n[SUCCESS] All tests passed (452/452)',
        ),
        PresubmitCheckResponse(
          attemptNumber: 2,
          buildName: selectedCheck!,
          creationTime: 0,
          status: 'Failed',
          summary:
              '[INFO] Starting task $selectedCheck...\n[ERROR] Test failed: Unit Tests',
        ),
      ];
      notifyListeners();
      return;
    }

    _isLoading = true;
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
    _isLoading = false;
    notifyListeners();
  }
}
