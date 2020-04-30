// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'package:app_flutter/logic/brooks.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/index.dart';

import 'mocks.dart';

class FakeIndexState extends ChangeNotifier implements IndexState {
  FakeIndexState({GoogleSignInService authService})
      : authService = authService ?? MockGoogleSignInService();

  @override
  final GoogleSignInService authService;

  @override
  final ErrorSink errors = ErrorSink();
}
