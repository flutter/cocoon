// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:meta/meta.dart';

import 'exceptions.dart';

@immutable
abstract interface class AuthenticationProvider {
  /// Authenticates the specified [request] and returns the associated
  /// [AuthenticatedContext].
  ///
  /// See the class documentation on [AuthenticationProvider] for a discussion
  /// of the different types of authentication that are accepted.
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  Future<AuthenticatedContext> authenticate(HttpRequest request);
}

/// Class that represents an authenticated request having been made, and any
/// attached metadata to that request.
///
/// See also:
///
///  * [AuthenticationProvider]
@immutable
class AuthenticatedContext {
  /// Creates a new [AuthenticatedContext].
  const AuthenticatedContext({
    required this.clientContext,
    required this.email,
  });

  /// The App Engine [ClientContext] of the current request.
  ///
  /// This is guaranteed to be non-null.
  final ClientContext clientContext;

  /// The email address associated with this authenticated context.
  final String email; // maybe TokenInfo
}
