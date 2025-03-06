// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
import '../model/google/token_info.dart';
import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s for infra endpoints.
///
/// This class implements an ACL on a [RequestHandler] to ensure only automated
/// systems can access the endpoints.
///
/// If the request has the `Service-Account-Token` HTTP header, the token
/// will be authenticated as a LUCI bot. This token is validated against
/// Google Auth APIs.
///
/// If none of the above authentication methods yield an authenticated
/// request, then the request is unauthenticated, and any call to
/// [authenticate] will throw an [Unauthenticated] exception.
@immutable
class SwarmingAuthenticationProvider extends AuthenticationProvider {
  const SwarmingAuthenticationProvider({
    required super.config,
    super.clientContextProvider = Providers.serviceScopeContext,
    super.httpClientProvider = Providers.freshHttpClient,
  });

  /// Name of the header that LUCI requests will put their service account token.
  static const String kSwarmingTokenHeader = 'Service-Account-Token';

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
    final swarmingToken = request.headers.value(kSwarmingTokenHeader);

    final clientContext = clientContextProvider();

    if (swarmingToken != null) {
      log.fine('Authenticating as swarming task');
      return authenticateAccessToken(
        swarmingToken,
        clientContext: clientContext,
      );
    }

    throw const Unauthenticated('Request rejected due to not from LUCI');
  }

  /// Authenticate [accessToken] against Google OAuth 2 API.
  ///
  /// Access tokens are the legacy authentication strategy for Google OAuth, where ID tokens
  /// are the new technique to use. LUCI auth only generates access tokens, and must be
  /// validated against a different endpoint. We only authenticate access tokens
  /// if they belong to a LUCI prod service account.
  ///
  /// If LUCI auth adds id tokens, we can switch to that and remove this.
  Future<AuthenticatedContext> authenticateAccessToken(
    String accessToken, {
    required ClientContext clientContext,
  }) async {
    // Authenticate as a signed-in Google account via OAuth id token.
    final client = httpClientProvider();
    try {
      log.fine('Sending token request to Google OAuth');
      final verifyTokenResponse = await client.get(
        Uri.https('oauth2.googleapis.com', '/tokeninfo', <String, String>{
          'access_token': accessToken,
        }),
      );

      if (verifyTokenResponse.statusCode != HttpStatus.ok) {
        /// Google Auth API returns a message in the response body explaining why
        /// the request failed. Such as "Invalid Token".
        final body = verifyTokenResponse.body;
        log.warning(
          'Token verification failed: ${verifyTokenResponse.statusCode}; $body',
        );
        throw const Unauthenticated('Invalid access token');
      }

      TokenInfo token;
      try {
        token = TokenInfo.fromJson(
          json.decode(verifyTokenResponse.body) as Map<String, dynamic>,
        );
      } on FormatException {
        log.warning('Failed to decode token JSON: ${verifyTokenResponse.body}');
        throw InternalServerError(
          'Invalid JSON: "${verifyTokenResponse.body}"',
        );
      }

      // Update is from Flutter LUCI builds
      if (token.email == Config.luciProdAccount) {
        return AuthenticatedContext(clientContext: clientContext);
      }

      if (token.email == Config.frobAccount) {
        log.fine('Authenticating as FRoB request');
        return AuthenticatedContext(clientContext: clientContext);
      }

      log.fine(verifyTokenResponse.body);
      log.warning('${token.email} is not allowed');
      throw Unauthenticated('${token.email} is not allowed');
    } finally {
      client.close();
    }
  }
}
