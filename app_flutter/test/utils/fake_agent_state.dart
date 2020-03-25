// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/agent.dart';
import 'package:app_flutter/state/brooks.dart';

import 'mocks.dart';

class FakeAgentState extends ChangeNotifier implements AgentState {
  FakeAgentState({
    GoogleSignInService authService,
    CocoonService cocoonService,
  })  : authService = authService ?? MockGoogleSignInService(),
        cocoonService = cocoonService ?? MockCocoonService();

  @override
  final GoogleSignInService authService;

  @override
  final CocoonService cocoonService;

  @override
  final ErrorSink errors = ErrorSink();

  @override
  Duration get refreshRate => null;

  @override
  List<Agent> agents = <Agent>[
    // We have to have at least one otherwise our logic assumes we have not yet
    // successfully fetched the agent list.
    // TODO(ianh): fix the logic to handle receiving an empty list and distingush
    // this from not yet having received any agents.
    Agent(),
  ];

  @override
  Future<String> authorizeAgent(Agent agent) async => 'abc123';

  @override
  Future<String> createAgent(String agentId, List<String> capabilities) async => 'def456';

  @override
  Future<void> reserveTask(Agent agent) => null;

  @override
  Timer refreshTimer;
}
