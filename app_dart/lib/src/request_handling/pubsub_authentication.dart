// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_server/logging.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
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
class PubsubAuthenticationProvider extends AuthenticationProvider {
  const PubsubAuthenticationProvider({
    required super.config,
    super.clientContextProvider = Providers.serviceScopeContext,
    super.httpClientProvider = Providers.freshHttpClient,
  });

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
    final String? idToken = request.headers.value(HttpHeaders.authorizationHeader);

    final ClientContext clientContext = clientContextProvider();

    log.fine('Authenticating as pubsub message');
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
    final Client client = httpClientProvider();
    final Oauth2Api oauth2api = Oauth2Api(client);

    // Get token from Google oauth
    final Tokeninfo info = await oauth2api.tokeninfo(
      idToken: idToken.substring(kBearerTokenPrefix.length),
    );
    if (info.expiresIn == null || info.expiresIn! < 1) {
      throw const Unauthenticated('Token is expired');
    }

    if (Config.allowedPubsubServiceAccounts.contains(info.email)) {
      return AuthenticatedContext(clientContext: clientContext);
    }
    throw Unauthenticated('${info.email} is not in allowedPubsubServiceAccounts');
  }
}
