// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/agent.dart';
import '../model/appengine/whitelisted_account.dart';
import '../model/google/token_info.dart';

import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s.
///
/// There are three types of authentication this class supports:
///
///  1. If the request has the `'Agent-ID'` HTTP header set to the ID of the
///     Cocoon agent making the request and the `'Agent-Auth-Token'` HTTP
///     header set to the hashed password of the agent, then the request will
///     be authenticated as a request being made on behalf of an agent, and the
///     [RequestContext.agent] field will be set.
///
///     The password should be hashed using the bcrypt algorithm. See
///     <https://en.wikipedia.org/wiki/Bcrypt> or
///     <https://www.usenix.org/legacy/event/usenix99/provos/provos.pdf> for
///     more details.
///
///  2. If the request has the `'X-Appengine-Cron'` HTTP header set to "true",
///     then the request will be authenticated as an App Engine cron job. The
///     [RequestContext.agent] field will be null (unless the request _also_
///     contained the aforementioned headers).
///
///     The `'X-Appengine-Cron'` HTTP header is set automatically by App Engine
///     and will be automatically stripped from the request by the App Engine
///     runtime if the request originated from anything other than a cron job.
///     Thus, the header is safe to trust as an authentication indicator.
///
///  3. If the request has the `'X-Flutter-IdToken'` HTTP cookie or HTTP header
///     set to a valid encrypted JWT token, then the request will be authenticated
///     as a user account. The [RequestContext.agent] field will be null
///     (unless the request _also_ contained the aforementioned headers).
///
///     User accounts are only authorized if the user is either a "@google.com"
///     account or is a whitelisted account in the Cocoon backend.
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
    this._config, {
    ClientContextProvider clientContextProvider = Providers.serviceScopeContext,
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
    LoggingProvider loggingProvider = Providers.serviceScopeLogger,
  })  : assert(_config != null),
        assert(clientContextProvider != null),
        assert(httpClientProvider != null),
        assert(loggingProvider != null),
        _clientContextProvider = clientContextProvider,
        _httpClientProvider = httpClientProvider,
        _loggingProvider = loggingProvider;

  /// The Cocoon config, guaranteed to be non-null.
  final Config _config;

  /// Provides the App Engine client context as part of the
  /// [AuthenticatedContext].
  ///
  /// This is guaranteed to be non-null.
  final ClientContextProvider _clientContextProvider;

  /// Provides the HTTP client that will be used (if necessary) to verify OAuth
  /// ID tokens (JWT tokens).
  ///
  /// This is guaranteed to be non-null.
  final HttpClientProvider _httpClientProvider;

  /// Provides the logger.
  ///
  /// This is guaranteed to be non-null.
  final LoggingProvider _loggingProvider;

  /// Authenticates the specified [request] and returns the associated
  /// [AuthenticatedContext].
  ///
  /// See the class documentation on [AuthenticationProvider] for a discussion
  /// of the different types of authentication that are accepted.
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    final String agentId = request.headers.value('Agent-ID');
    final bool isCron = request.headers.value('X-Appengine-Cron') == 'true';
    final String idTokenFromCookie = request.cookies
        .where((Cookie cookie) => cookie.name == 'X-Flutter-IdToken')
        .map<String>((Cookie cookie) => cookie.value)
        .followedBy(<String>[null]).first;
    final String idTokenFromHeader = request.headers.value('X-Flutter-IdToken');
    final ClientContext clientContext = _clientContextProvider();
    final Logging log = _loggingProvider();

    if (agentId != null) {
      // Authenticate as an agent. Note that it could simultaneously be cron
      // and agent, or Google account and agent.
      final Key agentKey = _config.db.emptyKey.append(Agent, id: agentId);
      final Agent agent =
          await _config.db.lookupValue<Agent>(agentKey, orElse: () {
        throw Unauthenticated('Invalid agent: $agentId');
      });

      if (!clientContext.isDevelopmentEnvironment) {
        final String agentAuthToken = request.headers.value('Agent-Auth-Token');
        if (agentAuthToken == null) {
          throw const Unauthenticated(
              'Missing required HTTP header: Agent-Auth-Token');
        }
        if (!_compareHashAndPassword(agent.authToken, agentAuthToken)) {
          throw Unauthenticated('Invalid agent: $agentId');
        }
      }

      return AuthenticatedContext._(agent: agent, clientContext: clientContext);
    } else if (isCron) {
      // Authenticate cron requests that are not agents.
      return AuthenticatedContext._(clientContext: clientContext);
    } else if (idTokenFromCookie != null || idTokenFromHeader != null) {
      /// There are two possible sources for an id token:
      ///
      /// 1. Angular Dart app sends it as a Cookie
      /// 2. Flutter app sends it as an HTTP header
      ///
      /// As long as one of these two id tokens are authenticated, the
      /// request is authenticated.
      if (idTokenFromCookie != null) {
        /// The case where [idTokenFromCookie] is not valid but [idTokenFromHeader]
        /// is requires us to catch the thrown [Unauthenticated] exception.
        try {
          return await authenticateIdToken(idTokenFromCookie,
              clientContext: clientContext, log: log);
        } on Unauthenticated {
          log.debug('Failed to authenticate cookie id token');
        }
      }

      if (idTokenFromHeader != null) {
        return authenticateIdToken(idTokenFromHeader,
            clientContext: clientContext, log: log);
      }
    }

    throw const Unauthenticated('User is not signed in');
  }

  @visibleForTesting
  Future<AuthenticatedContext> authenticateIdToken(String idToken,
      {ClientContext clientContext, Logging log}) async {
    // Authenticate as a signed-in Google account via OAuth id token.
    final HttpClient client = _httpClientProvider();
    try {
      final HttpClientRequest verifyTokenRequest =
          await client.getUrl(Uri.https(
        'oauth2.googleapis.com',
        '/tokeninfo',
        <String, String>{
          'id_token': idToken,
        },
      ));
      final HttpClientResponse verifyTokenResponse =
          await verifyTokenRequest.close();

      if (verifyTokenResponse.statusCode != HttpStatus.ok) {
        /// Google Auth API returns a message in the response body explaining why
        /// the request failed. Such as "Invalid Token".
        final String body = await utf8.decodeStream(verifyTokenResponse);
        log.warning(
            'Token verification failed: ${verifyTokenResponse.statusCode}; $body');
        throw const Unauthenticated('Invalid ID token');
      }

      final String tokenJson = await utf8.decodeStream(verifyTokenResponse);
      TokenInfo token;
      try {
        token = TokenInfo.fromJson(json.decode(tokenJson));
      } on FormatException {
        throw InternalServerError('Invalid JSON: "$tokenJson"');
      }

      final String clientId = await _config.oauthClientId;
      assert(clientId != null);
      if (token.audience != clientId) {
        log.warning(
            'Possible forged token: "${token.audience}" (expected "$clientId")');
        throw const Unauthenticated('Invalid ID token');
      }

      if (token.hostedDomain != 'google.com') {
        final bool isWhitelisted = await _isWhitelisted(token.email);
        if (!isWhitelisted) {
          throw Unauthenticated(
              '${token.email} is not authorized to access the dashboard');
        }
      }

      return AuthenticatedContext._(clientContext: clientContext);
    } finally {
      client.close();
    }
  }

  Future<bool> _isWhitelisted(String email) async {
    final Query<WhitelistedAccount> query =
        _config.db.query<WhitelistedAccount>()
          ..filter('email =', email)
          ..limit(20);

    return !(await query.run().isEmpty);
  }

  // This method is expensive (run time of ~1,500ms!). If the server starts
  // handling any meaningful API traffic, we should move request processing
  // to dedicated isolates in a pool.
  static bool _compareHashAndPassword(
      List<int> serverAuthTokenHash, String clientAuthToken) {
    final String serverAuthTokenHashAscii = ascii.decode(serverAuthTokenHash);
    final DBCrypt crypt = DBCrypt();
    try {
      return crypt.checkpw(clientAuthToken, serverAuthTokenHashAscii);
    } on String catch (error) {
      // The bcrypt password hash in the cloud datastore is invalid.
      throw InternalServerError(error);
    }
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
  const AuthenticatedContext._({
    this.agent,
    @required this.clientContext,
  }) : assert(clientContext != null);

  /// The agent making the request.
  ///
  /// This will be null if the request is not being made by an agent. Even if
  /// this property is null, the request has been authenticated (by virtue of
  /// the request context having been created).
  final Agent agent;

  /// The App Engine [ClientContext] of the current request.
  ///
  /// This is guaranteed to be non-null.
  final ClientContext clientContext;
}
