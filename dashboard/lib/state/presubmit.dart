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

  /// Update the current parameters and trigger fetches if needed.
  ///
  /// This method is idempotent and safe to call during build (it uses Future.microtask
  /// internally if notifyListeners is needed).
  void update({String? repo, String? pr, String? sha}) {
    if (_syncParameters(repo: repo, pr: pr, sha: sha)) {
      notifyListeners();
    }
    _fetchIfNeeded();
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
    if (this.pr != pr) {
      this.pr = pr;
      changed = true;
      _availableSummaries = [];
    }
    if (this.sha != sha) {
      this.sha = sha;
      changed = true;
      _guardResponse = null;
      _selectedCheck = null;
      _checks = null;
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

  void _fetchIfNeeded() {
    if (pr != null && _availableSummaries.isEmpty && !_isLoading) {
      fetchAvailableShas();
    } else if (sha != null && _guardResponse == null && !_isLoading) {
      fetchGuardStatus();
    }
  }

  /// Request the latest available SHAs for the current [pr] from [CocoonService].
  Future<void> fetchAvailableShas() async {
    if (pr == null) {
      return;
    }
    _isLoading = true;
    // We don't notify here to allow calling from build/didChangeDependencies

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
  }

  /// Request the guard status for the current [sha] from [CocoonService].
  Future<void> fetchGuardStatus() async {
    if (sha == null) {
      return;
    }
    _isLoading = true;
    // We don't notify here to allow calling from build/didChangeDependencies

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
    if (selectedCheck == null || guardResponse == null) {
      return;
    }

    // Handle mock SHAs
    if (sha?.startsWith('mock_sha_') ?? false) {
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
