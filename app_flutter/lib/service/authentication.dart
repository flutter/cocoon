// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_sign_in_all/google_sign_in_all.dart';

import 'google_authentication.dart';

/// Service class for interacting with authentication to Cocoon backend.
///
/// This service exists to have a universal location for all the authentication operations.
abstract class AuthenticationService {
  /// Creates a new [AuthenticationService].
  factory AuthenticationService({AuthenticationService service}) {
    return service ?? GoogleAuthenticationService();
  }

  /// Whether or not the application has been signed in to.
  bool get isAuthenticated;

  /// The email of the current user signed in.
  String get email;

  /// The profile photo url of the current user signed in.
  String get avatarUrl;

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  String get accessToken;

  /// Initiate the [GoogleSignIn] process.
  Future<void> signIn();
}
