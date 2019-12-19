// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../service/cocoon.dart';
import '../service/google_authentication.dart';

/// State for the index page
class IndexState extends ChangeNotifier {
  /// Creates a new [FlutterBuildState].
  ///
  /// If [CocoonService] is not specified, a new [CocoonService] instance is created.
  IndexState({
    GoogleSignInService authServiceValue,
  }) {
    authService = authServiceValue ??
        GoogleSignInService(notifyListeners: notifyListeners);
  }

  /// Authentication service for managing Google Sign In.
  GoogleSignInService authService;

  /// A [ChangeNotifer] for knowing when errors occur that relate to this [IndexState].
  IndexStateErrors errors = IndexStateErrors();

  Future<void> signIn() => authService.signIn();
  Future<void> signOut() => authService.signOut();
}

class IndexStateErrors extends ChangeNotifier {
  String message;
}
