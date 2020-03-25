// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import '../service/cocoon.dart';
import '../service/google_authentication.dart';

import 'brooks.dart';

/// State for the agents in Flutter infra.
class AgentState extends ChangeNotifier {
  AgentState({
    @required this.cocoonService,
    @required this.authService,
  }) {
    authService.addListener(notifyListeners);
  }

  /// Cocoon backend service that retrieves the data needed for current infra status.
  final CocoonService cocoonService;

  /// Authentication service for managing Google Sign In.
  final GoogleSignInService authService;

  /// How often to query the Cocoon backend for the current agent statuses.
  @visibleForTesting
  final Duration refreshRate = const Duration(minutes: 1);

  /// Timer that calls [_fetchAgentStatusUpdate] on a set interval.
  @visibleForTesting
  @protected
  Timer refreshTimer;

  /// The current status of the commits loaded.
  List<Agent> _agents = <Agent>[];
  List<Agent> get agents => _agents;

  /// A [Brook] that reports when errors occur that relate to this [AgentState].
  Brook<String> get errors => _errors;
  final ErrorSink _errors = ErrorSink();

  @visibleForTesting
  static const String errorMessageFetchingStatuses = 'An error occured fetching agent statuses from Cocoon';

  @visibleForTesting
  static const String errorMessageCreatingAgent = 'An error occurred creating agent';

  @visibleForTesting
  static const String errorMessageAuthorizingAgent = 'An error occurred authorizing agent';

  /// Start a fixed interval loop that fetches build state updates based on [refreshRate].
  // TODO(ianh): make this automatically trigger when listeners are added, and cancel when they're removed.
  Future<void> startFetchingStateUpdates() async {
    if (refreshTimer != null) {
      // There's already an update loop, no need to make another.
      return;
    }

    /// [Timer.periodic] does not necessarily run at the start of the timer.
    _fetchAgentStatusUpdate();

    refreshTimer = Timer.periodic(refreshRate, (_) => _fetchAgentStatusUpdate());
  }

  /// Request the latest agent statuses from [CocoonService].
  ///
  /// If an error occurs, [errors] will be updated with
  /// the message [errorMessageFetchingStatuses].
  Future<void> _fetchAgentStatusUpdate() async {
    await Future.wait(<Future<void>>[
      cocoonService.fetchAgentStatuses().then((CocoonResponse<List<Agent>> response) {
        if (response.error != null) {
          _errors.send('$errorMessageFetchingStatuses: ${response.error}');
        } else {
          _agents = response.data;
        }
        notifyListeners();
      }),
    ]);
  }

  /// Create [Agent] in Cocoon.
  ///
  /// If an error occurs, [errors] will be updated with
  /// the message [errorMessageCreatingAgent].
  Future<String> createAgent(String agentId, List<String> capabilities) async {
    final CocoonResponse<String> response = await cocoonService.createAgent(
      agentId,
      capabilities,
      await authService.idToken,
    );
    if (response.error != null) {
      _errors.send('$errorMessageCreatingAgent: ${response.error}');
    }
    return response.data;
  }

  /// Generates a new access token for [agent].
  ///
  /// If an error occurs, [errors] will be updated with
  /// the message [errorMessageAuthorizingAgent].
  Future<String> authorizeAgent(Agent agent) async {
    final CocoonResponse<String> response = await cocoonService.authorizeAgent(agent, await authService.idToken);
    if (response.error != null) {
      _errors.send('$errorMessageAuthorizingAgent: ${response.error}');
    }
    return response.data;
  }

  /// Attempt to assign a new task to [agent].
  ///
  /// If no task can be assigned, a null value is returned.
  Future<void> reserveTask(Agent agent) async => cocoonService.reserveTask(agent, await authService.idToken);

  @override
  void dispose() {
    authService.removeListener(notifyListeners);
    refreshTimer?.cancel();
    super.dispose();
  }
}
