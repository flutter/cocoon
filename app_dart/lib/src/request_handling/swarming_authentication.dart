// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/agent.dart';

import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s for infra endpoints.
///
/// This class implements an ACL on a [RequestHandler] to ensure only automated
/// systems can access the endpoints.
///
/// There are two types of authentication this class supports:
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
///  2. If the request has the `Service-Account-Token` HTTP header, the token
///     will be authenticated as a LUCI bot. This token is validated against
///     Google Auth APIs.
///
/// If none of the above authentication methods yield an authenticated
/// request, then the request is unauthenticated, and any call to
/// [authenticate] will throw an [Unauthenticated] exception.
// TODO(chillers): Remove (1) when DeviceLab has migrated to LUCI, https://github.com/flutter/flutter/projects/151#card-47536851
@immutable
class SwarmingAuthenticationProvider extends AuthenticationProvider {
  const SwarmingAuthenticationProvider(
    Config config, {
    ClientContextProvider clientContextProvider = Providers.serviceScopeContext,
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
    LoggingProvider loggingProvider = Providers.serviceScopeLogger,
  }) : super(
          config,
          clientContextProvider: clientContextProvider,
          httpClientProvider: httpClientProvider,
          loggingProvider: loggingProvider,
        );

  /// Name of the header that Cocoon agent requests will put their token.
  static const String kAgentIdHeader = 'Agent-ID';

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
    final String agentId = request.headers.value(kAgentIdHeader);
    final String swarmingToken = request.headers.value(kSwarmingTokenHeader);

    final ClientContext clientContext = clientContextProvider();
    final Logging log = loggingProvider();

    if (agentId != null) {
      // Authenticate as an agent. Note that it could simultaneously be cron
      // and agent, or Google account and agent.
      final Key agentKey = config.db.emptyKey.append(Agent, id: agentId);
      final Agent agent = await config.db.lookupValue<Agent>(agentKey, orElse: () {
        throw Unauthenticated('Invalid agent: $agentId');
      });

      if (!clientContext.isDevelopmentEnvironment) {
        final String agentAuthToken = request.headers.value('Agent-Auth-Token');
        if (agentAuthToken == null) {
          throw const Unauthenticated('Missing required HTTP header: Agent-Auth-Token');
        }
        if (!compareHashAndPassword(agent.authToken, agentAuthToken)) {
          throw Unauthenticated('Invalid agent: $agentId');
        }
      }

      return AuthenticatedContext(agent: agent, clientContext: clientContext);
    } else if (swarmingToken != null) {
      log.debug('Authenticating as swarming task');
      return await authenticateAccessToken(swarmingToken, clientContext: clientContext, log: log);
    }

    throw const Unauthenticated('Request rejected due to not from LUCI or Cocoon agent');
  }

  /// Authenticate [accessToken] against Google OAuth 2 API.
  ///
  /// Access tokens are the legacy authentication strategy for Google OAuth, where ID tokens
  /// are the new technique to use. LUCI auth only generates access tokens, and must be
  /// validated against a different endpoint. We only authenticate access tokens
  /// if they belong to a LUCI prod service account.
  ///
  /// If LUCI auth adds id tokens, we can switch to that and remove this.
  Future<AuthenticatedContext> authenticateAccessToken(String accessToken,
      {ClientContext clientContext, Logging log}) async {
    // Authenticate as a signed-in Google account via OAuth id token.
    final HttpClient client = httpClientProvider();
    try {
      log.debug('Sending token request to Google OAuth');
      final HttpClientRequest verifyTokenRequest = await client.getUrl(Uri.https(
        'oauth2.googleapis.com',
        '/tokeninfo',
        <String, String>{
          'access_token': accessToken,
        },
      ));
      final HttpClientResponse verifyTokenResponse = await verifyTokenRequest.close();

      if (verifyTokenResponse.statusCode != HttpStatus.ok) {
        /// Google Auth API returns a message in the response body explaining why
        /// the request failed. Such as "Invalid Token".
        final String body = await utf8.decodeStream(verifyTokenResponse);
        log.warning('Token verification failed: ${verifyTokenResponse.statusCode}; $body');
        throw const Unauthenticated('Invalid access token');
      }

      final String tokenJson = await utf8.decodeStream(verifyTokenResponse);
      TokenInfo token;
      try {
        token = TokenInfo.fromJson(json.decode(tokenJson) as Map<String, dynamic>);
      } on FormatException {
        log.warning('Failed to decode token JSON: $tokenJson');
        throw InternalServerError('Invalid JSON: "$tokenJson"');
      }

      if (token.email == config.luciProdAccount) {
        return AuthenticatedContext(clientContext: clientContext);
      }

      log.warning('${token.email} is not allowed');
      throw Unauthenticated('${token.email} is not allowed');
    } finally {
      client.close();
    }
  }
}
