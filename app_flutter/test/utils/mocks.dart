// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/agent.dart';
import 'package:app_flutter/state/build.dart';

class MockAgentState extends Mock implements AgentState {}

class MockCocoonService extends Mock implements CocoonService {}

class MockBuildState extends Mock implements BuildState {}

class MockGoogleSignInPlugin extends Mock implements GoogleSignIn {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}
