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

  /// Update the current state and notify listeners.
  void update({String? repo, String? pr, String? sha}) {
    if (this.repo == repo && this.pr == pr && this.sha == sha) {
      return;
    }
    if (repo != null) {
      this.repo = repo;
    }
    this.pr = pr;
    this.sha = sha;
    notifyListeners();
  }

  /// Request the latest available SHAs for the current [pr] from [CocoonService].
  Future<void> fetchAvailableShas() async {
    if (pr == null) {
      return;
    }
    _isLoading = true;
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
  }

  /// Request the guard status for the current [sha] from [CocoonService].
  Future<void> fetchGuardStatus() async {
    if (sha == null) {
      return;
    }
    _isLoading = true;
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
}
