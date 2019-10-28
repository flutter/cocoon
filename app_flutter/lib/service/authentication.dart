// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'google_authentication.dart';

/// Service class for interacting with authentication to Cocoon backend.
///
/// This service exists to have a universal location for all the authentication information.
abstract class AuthenticationService {
  /// Creates a new [AuthenticationService] based on if Flutter app is in production.
  ///
  /// Production uses the Google Sign In service.
  factory AuthenticationService({AuthenticationService service}) {
    if (service != null) {
      return service;
    }

    return GoogleAuthenticationService();
  }

  /// Whether or not the application has been logged in to.
  bool get isAuthenticated;

  /// The email of the current user logged in.
  String get email;

  /// The avatar url of the current user logged in.
  String get avatarUrl;

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  String get accessToken;

  /// Initiate the [GoogleSignIn] process.
  Future<bool> signIn();
}
