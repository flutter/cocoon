// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show kReleaseMode;

/// Service class for interacting with authentication to Cocoon backend.
/// 
/// This service exists to have a universal location for all the authentication information.
abstract class AuthenticationService {
  /// Creates a new [AuthenticationService] based on if Flutter app is in production.
  /// 
  /// Production uses the Google Sign In service.
  /// Otherwise, use fake data that mimicks being authenticated.
  factory AuthenticationService() {
    if (kReleaseMode) {

    }

    return null;
  }

  /// Whether or not the application has been logged in to.
  bool get isAuthenticated => _isAuthenticated;
  bool _isAuthenticated = false;

  /// The email of the current user logged in.
  String get email => _email;
  String _email;

  /// The avatar url of the current user logged in.
  String get avatarUrl => _avatarUrl;
  String _avatarUrl;

  /// Initiate the [GoogleSignIn] process.
  Future<bool> signIn();
}