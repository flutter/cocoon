// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../requests/exceptions.dart';
import '../service/config.dart';

/// Class capable of authenticating [HttpRequest]s.
///
///  If the request has the `'X-Appengine-Cron'` HTTP header set to "true",
///  then the request will be authenticated as an App Engine cron job.
///
///  The `'X-Appengine-Cron'` HTTP header is set automatically by App Engine
///  and will be automatically stripped from the request by the App Engine
///  runtime if the request originated from anything other than a cron job.
///  Thus, the header is safe to trust as an authentication indicator.
///
///
/// If none of the above authentication methods yield an authenticated
/// request, then the request is unauthenticated, and any call to
/// [authenticate] will throw an [Unauthenticated] exception.
///
/// See also:
///
///  * <https://cloud.google.com/appengine/docs/standard/python/reference/request-response-headers>
@immutable
class AuthenticationProvider {
  const AuthenticationProvider(
    this.config, {
    this.clientContextProvider = Providers.serviceScopeContext,
    this.httpClientProvider = Providers.freshHttpClient,
  });

  /// The Cocoon config, guaranteed to be non-null.
  final Config config;

  /// Provides the App Engine client context as part of the
  /// [AuthenticatedContext].
  ///
  /// This is guaranteed to be non-null.
  final ClientContextProvider clientContextProvider;

  /// Provides the HTTP client that will be used (if necessary) to verify OAuth
  /// ID tokens (JWT tokens).
  ///
  /// This is guaranteed to be non-null.
  final HttpClientProvider httpClientProvider;

  /// Authenticates the specified [request] and returns the associated
  /// [AuthenticatedContext].
  ///
  /// See the class documentation on [AuthenticationProvider] for a discussion
  /// of the different types of authentication that are accepted.
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  Future<AuthenticatedContext> authenticate(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    final bool isCron = reqHeader['X-Appengine-Cron'] == 'true';
    final ClientContext clientContext = clientContextProvider();

    if (isCron) {
      // Authenticate cron requests
      return AuthenticatedContext(clientContext: clientContext);
    }

    throw const Unauthenticated('User is not signed in');
  }
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
  });

  /// The App Engine [ClientContext] of the current request.
  ///
  /// This is guaranteed to be non-null.
  final ClientContext clientContext;
}
