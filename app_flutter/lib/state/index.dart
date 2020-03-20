// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../service/cocoon.dart';
import '../service/google_authentication.dart';

import 'brooks.dart';

/// State for the index page
class IndexState extends ChangeNotifier {
  /// Creates a new [FlutterBuildState].
  ///
  /// If [CocoonService] is not specified, a new [CocoonService] instance is created.
  IndexState({
    GoogleSignInService authServiceValue,
  }) : authService = authServiceValue ?? GoogleSignInService() {
    authService.notifyListeners = notifyListeners;
  }

  /// Authentication service for managing Google Sign In.
  GoogleSignInService authService;

  /// A [Brook] that reports when errors occur that relate to this [IndexState].
  ///
  /// Currently no errors are ever reported here.
  Brook<String> get errors => _errors;
  final ErrorSink _errors = ErrorSink();

  Future<void> signIn() => authService.signIn();
  Future<void> signOut() => authService.signOut();
}
