// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/allowed_account.dart';
import '../model/google/token_info.dart';
import '../service/logging.dart';
import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s.
///
/// There are two types of authentication this class supports:
///
///  1. If the request has the `'X-Appengine-Cron'` HTTP header set to "true",
///     then the request will be authenticated as an App Engine cron job.
///
///     The `'X-Appengine-Cron'` HTTP header is set automatically by App Engine
///     and will be automatically stripped from the request by the App Engine
///     runtime if the request originated from anything other than a cron job.
///     Thus, the header is safe to trust as an authentication indicator.
///
///  2. If the request has the `'X-Flutter-IdToken'` HTTP header
///     set to a valid encrypted JWT token, then the request will be authenticated
///     as a user account.
///
///     @google.com accounts can call APIs using curl and gcloud.
///     E.g. curl '<api_url>' -H "X-Flutter-IdToken: $(gcloud auth print-identity-token)"
///
///     User accounts are only authorized if the user is either a "@google.com"
///     account or is an [AllowedAccount] in Cocoon's Datastore.
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
  const AuthenticationProvider({
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

  /// Authenticates the specified [request] and returns the associated
  /// [AuthenticatedContext].
  ///
  /// See the class documentation on [AuthenticationProvider] for a discussion
  /// of the different types of authentication that are accepted.
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    final bool isCron = request.headers.value('X-Appengine-Cron') == 'true';
    final String? idTokenFromHeader = request.headers.value('X-Flutter-IdToken');
    final ClientContext clientContext = clientContextProvider();
    if (isCron) {
      // Authenticate cron requests
      return AuthenticatedContext(clientContext: clientContext);
    } else if (idTokenFromHeader != null) {
      TokenInfo token;
      try {
        token = await tokenInfo(request);
      } on Unauthenticated {
        token = await tokenInfo(request, tokenType: 'access_token');
      }
      return authenticateToken(token, clientContext: clientContext);
    }

    throw const Unauthenticated('User is not signed in');
  }

  /// Gets oauth token information. This method requires the token to be stored in
  /// X-Flutter-IdToken header.
  Future<TokenInfo> tokenInfo(HttpRequest request, {String tokenType = 'id_token'}) async {
    final String? idTokenFromHeader = request.headers.value('X-Flutter-IdToken');
    final http.Client client = httpClientProvider();
    try {
      final http.Response verifyTokenResponse = await client.get(
        Uri.https(
          'oauth2.googleapis.com',
          '/tokeninfo',
          <String, String?>{
            tokenType: idTokenFromHeader,
          },
        ),
      );

      if (verifyTokenResponse.statusCode != HttpStatus.ok) {
        /// Google Auth API returns a message in the response body explaining why
        /// the request failed. Such as "Invalid Token".
        log.fine('Token verification failed: ${verifyTokenResponse.statusCode}; ${verifyTokenResponse.body}');
        throw const Unauthenticated('Invalid ID token');
      }

      try {
        return TokenInfo.fromJson(json.decode(verifyTokenResponse.body) as Map<String, dynamic>);
      } on FormatException {
        throw InternalServerError('Invalid JSON: "${verifyTokenResponse.body}"');
      }
    } finally {
      client.close();
    }
  }

  Future<AuthenticatedContext> authenticateToken(TokenInfo token, {required ClientContext clientContext}) async {
    // Authenticate as a signed-in Google account via OAuth id token.
    final String clientId = await config.oauthClientId;
    if (token.audience != clientId && !token.email!.endsWith('@google.com')) {
      log.warning('Possible forged token: "${token.audience}" (expected "$clientId")');
      throw const Unauthenticated('Invalid ID token');
    }

    if (token.hostedDomain != 'google.com') {
      final bool isAllowed = await _isAllowed(token.email);
      if (!isAllowed) {
        throw Unauthenticated('${token.email} is not authorized to access the dashboard');
      }
    }
    return AuthenticatedContext(clientContext: clientContext);
  }

  Future<bool> _isAllowed(String? email) async {
    final Query<AllowedAccount> query = config.db.query<AllowedAccount>()
      ..filter('email =', email)
      ..limit(20);

    return !(await query.run().isEmpty);
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
