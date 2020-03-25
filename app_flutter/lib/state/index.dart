// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../service/google_authentication.dart';

import 'brooks.dart';

/// State for the index page.
class IndexState extends ChangeNotifier {
  /// Creates a new [IndexState].
  IndexState({
    this.authService,
  }) {
    authService.addListener(notifyListeners);
  }

  /// Authentication service for managing Google Sign In.
  final GoogleSignInService authService;

  /// A [Brook] that reports when errors occur that relate to this [IndexState].
  ///
  /// Currently no errors are ever reported here.
  Brook<String> get errors => _errors;
  final ErrorSink _errors = ErrorSink();

  @override
  void dispose() {
    authService.removeListener(notifyListeners);
    super.dispose();
  }
}
