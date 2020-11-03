// Copyright 2019 The Flutter Authors. All rights reserved.
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
    this._config, {
    this.clientContextProvider = Providers.serviceScopeContext,
    this.loggingProvider = Providers.serviceScopeLogger,
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
  }) : super(
          _config,
          clientContextProvider: clientContextProvider,
          httpClientProvider: httpClientProvider,
          loggingProvider: loggingProvider,
        );

  /// The Cocoon config, guaranteed to be non-null.
  final Config _config;

  /// Provides the App Engine client context as part of the
  /// [AuthenticatedContext].
  ///
  /// This is guaranteed to be non-null.
  final ClientContextProvider clientContextProvider;

  /// Provides the logger.
  ///
  /// This is guaranteed to be non-null.
  final LoggingProvider loggingProvider;

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

      return AuthenticatedContext(agent: agent, clientContext: clientContext);
    } else if (swarmingToken != null) {
      return await authenticateIdToken(swarmingToken, clientContext: clientContext, log: log);
    }

    throw const Unauthenticated('Request rejected due to not from LUCI or Cocoon agent');
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
