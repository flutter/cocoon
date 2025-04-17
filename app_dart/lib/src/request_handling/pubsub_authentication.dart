// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_server/logging.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s for PubSub messages.
///
/// This class implements an ACL on a [RequestHandler] to ensure only automated
/// systems can access the endpoints.
///
/// If the request has [HttpHeaders.authorizationHeader], the token
/// will be authenticated as a LUCI bot. This token is validated against
/// Google Auth APIs.
///
/// If there is no token, or it cannot be authenticated, [Unauthenticated] is thrown.
@immutable
class PubsubAuthenticationProvider implements AuthenticationProvider {
  const PubsubAuthenticationProvider({
    required this.config,
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

  static const String kBearerTokenPrefix = 'Bearer ';

  /// Authenticates the specified [request] and returns the associated
  /// [AuthenticatedContext].
  ///
  /// See the class documentation on [AuthenticationProvider] for a discussion
  /// of the different types of authentication that are accepted.
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    final idToken = request.headers.value(HttpHeaders.authorizationHeader);

    final clientContext = clientContextProvider();

    log.debug('Authenticating as pubsub message');
    return authenticateIdToken(idToken, clientContext: clientContext);
  }

  /// Authenticate [idToken] against Google OAuth 2 API.
  Future<AuthenticatedContext> authenticateIdToken(
    String? idToken, {
    required ClientContext clientContext,
  }) async {
    if (idToken == null || !idToken.startsWith(kBearerTokenPrefix)) {
      throw const Unauthenticated('${HttpHeaders.authorizationHeader} is null');
    }
    final client = httpClientProvider();
    final oauth2api = Oauth2Api(client);

    // Get token from Google oauth
    final info = await oauth2api.tokeninfo(
      idToken: idToken.substring(kBearerTokenPrefix.length),
    );
    if (info.expiresIn == null || info.expiresIn! < 1) {
      throw const Unauthenticated('Token is expired');
    }

    if (Config.allowedPubsubServiceAccounts.contains(info.email)) {
      return AuthenticatedContext(
        clientContext: clientContext,
        email: info.email!,
      );
    }
    throw Unauthenticated(
      '${info.email} is not in allowedPubsubServiceAccounts',
    );
  }
}
