// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/agent.dart';
import '../model/appengine/whitelisted_account.dart';
import '../model/google/token_info.dart';

import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s.
///
/// There are four types of authentication this class supports:
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
///  3. If the request has the `'X-Flutter-IdToken'` HTTP cookie set to a valid
///     encrypted JWT token, then the request will be authenticated as a user
///     account. The [RequestContext.agent] field will be null (unless the
///     request _also_ contained the aforementioned headers).
///
///     User accounts are only authorized if the user is either a "@google.com"
///     account or is a whitelisted account in the Cocoon backend.
/// 
///  4. If the request has the `'X-Flutter-AccessToken'` HTTP header set to a valid
///     access token, then this will follow the same logic as #3.
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
    final String idToken = request.cookies
        .where((Cookie cookie) => cookie.name == 'X-Flutter-IdToken')
        .map<String>((Cookie cookie) => cookie.value)
        .followedBy(<String>[null]).first;
    final String accessToken = request.headers.value('X-Flutter-AccessToken');
        
    final ClientContext clientContext = _clientContextProvider();
    final Logging log = _loggingProvider();

    if (agentId != null) {
      // Authenticate as an agent. Note that it could simultaneously be cron
      // and agent, or Google account and agent.
      final Key agentKey = _config.db.emptyKey.append(Agent, id: agentId);
      final Agent agent = await _config.db.lookupValue<Agent>(agentKey, orElse: () {
        throw Unauthenticated('Invalid agent: $agentId');
      });

      if (!clientContext.isDevelopmentEnvironment) {
        final String agentAuthToken = request.headers.value('Agent-Auth-Token');
        if (agentAuthToken == null) {
          throw const Unauthenticated('Missing required HTTP header: Agent-Auth-Token');
        }
        if (!_compareHashAndPassword(agent.authToken, agentAuthToken)) {
          throw Unauthenticated('Invalid agent: $agentId');
        }
      }

      return AuthenticatedContext._(agent: agent, clientContext: clientContext);
    } else if (isCron) {
      // Authenticate cron requests that are not agents.
      return AuthenticatedContext._(clientContext: clientContext);
    } else if (idToken != null) {
      // Authenticate as a signed-in Google account via OAuth id token.
      final HttpClient client = _httpClientProvider();
      try {
        final HttpClientRequest verifyTokenRequest = await client.getUrl(Uri.https(
          'oauth2.googleapis.com',
          '/tokeninfo',
          <String, String>{
            'id_token': idToken,
          },
        ));
        final HttpClientResponse verifyTokenResponse = await verifyTokenRequest.close();

        if (verifyTokenResponse.statusCode != HttpStatus.ok) {
          final String body = await utf8.decodeStream(verifyTokenResponse);
          log.warning('Token verification failed: ${verifyTokenResponse.statusCode}; $body');
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
          log.warning('Possible forged token: "${token.audience}" (expected "$clientId")');
          throw const Unauthenticated('Invalid ID token');
        }

        if (token.hostedDomain != 'google.com') {
          final bool isWhitelisted = await _isWhitelisted(token.email);
          if (!isWhitelisted) {
            throw Unauthenticated('${token.email} is not authorized to access the dashboard');
          }
        }

        return AuthenticatedContext._(clientContext: clientContext);
      } finally {
        client.close();
      }
    } else if (accessToken != null) {
      return authenticateAccessToken(accessToken: accessToken, clientContext: clientContext, log: log);
    } else {
      throw const Unauthenticated('User is not signed in');
    }
  }

  /// Verify [accessToken] with Google Auth, and return an [AuthenticatedContext] if
  /// it is verified to have access to the Cocoon backend.
  /// 
  /// Otherwise, throw [Unauthenticated] exception.
  Future<AuthenticatedContext> authenticateAccessToken({
    @required String accessToken,
    @required ClientContext clientContext,
    @required Logging log,
  }) async {
    final HttpClient client = _httpClientProvider();
    try {
      final Uri googleOauthTokenInfoUri = Uri.https(
        'www.googleapis.com',
        '/oauth2/v1/tokeninfo',
        <String, String>{
          'access_token': accessToken,
        },
      );
      log.info(googleOauthTokenInfoUri.toString());
      final HttpClientRequest verifyAccessTokenRequest = await client.getUrl(googleOauthTokenInfoUri);
      final HttpClientResponse verifyAccessTokenResponse = await verifyAccessTokenRequest.close();

      /// This also checks for when an access token is expired.
      if (verifyAccessTokenResponse.statusCode != HttpStatus.ok) {
        final String body = await utf8.decodeStream(verifyAccessTokenResponse);
        log.warning('Access token verification failed: ${verifyAccessTokenResponse.statusCode}; $body');
        throw const Unauthenticated('Invalid access token');
      }

      final String accessTokenJson = await utf8.decodeStream(verifyAccessTokenResponse);
      Map<String, dynamic> accessTokenData;
      try {
        accessTokenData = json.decode(accessTokenJson);
      } on FormatException {
        throw InternalServerError('Invalid JSON: "$accessTokenJson"');
      }

      final String clientId = await _config.oauthClientId;
      assert(clientId != null);
      if (accessTokenData['audience'] != clientId) {
        log.warning('Possible forged token: "${accessTokenData['audience']}" (expected "$clientId")');
        throw const Unauthenticated('Invalid ID token');
      }

      final String verifiedEmail = accessTokenData['verified_email'];
      assert(verifiedEmail != null);
      if (verifiedEmail != 'true') {
        log.warning('Unverified account attempted to authenticate');
        throw const Unauthenticated('Account is not verified');
      }

      /// This assumes the hosted domain will always be after the last @ sign.
      /// 
      /// Trivially, 'sundar@google.com' will return 'google.com'.
      /// A larger example is that 'sundarloves@signs@google.com' will also return 'google.com'.
      final String hostedDomain = accessTokenData['email'].toString().split('@').last;
      if (hostedDomain != 'google.com') {
        final bool isWhitelisted = await _isWhitelisted(accessTokenData['email']);
        if (!isWhitelisted) {
          throw Unauthenticated('${accessTokenData['email']} is not authorized to access the dashboard');
        }
      }

      return AuthenticatedContext._(clientContext: clientContext);
    } finally {
      client.close();
    }
  }

  Future<bool> _isWhitelisted(String email) async {
    final Query<WhitelistedAccount> query = _config.db.query<WhitelistedAccount>()
      ..filter('Email =', email)
      ..limit(20);

    return !(await query.run().isEmpty);
  }

  // This method is expensive (run time of ~1,500ms!). If the server starts
  // handling any meaningful API traffic, we should move request processing
  // to dedicated isolates in a pool.
  static bool _compareHashAndPassword(List<int> serverAuthTokenHash, String clientAuthToken) {
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
