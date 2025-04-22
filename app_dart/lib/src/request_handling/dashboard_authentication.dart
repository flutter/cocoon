// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/firestore/account.dart';
import '../model/google/token_info.dart';
import '../service/firebase_jwt_validator.dart';
import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s from the Dashboard
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
///     account or is an [AllowedAccount] in Cocoon's Firestore.
///
/// If none of the above authentication methods yield an authenticated
/// request, then the request is unauthenticated, and any call to
/// [authenticate] will throw an [Unauthenticated] exception.
///
/// See also:
///
///  * <https://cloud.google.com/appengine/docs/standard/python/reference/request-response-headers>
@immutable
interface class DashboardAuthentication implements AuthenticationProvider {
  DashboardAuthentication({
    required Config config,
    required FirebaseJwtValidator firebaseJwtValidator,
    required FirestoreService firestore,
    ClientContextProvider clientContextProvider = Providers.serviceScopeContext,
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
  }) {
    _authenticationChain.addAll([
      DashboardCronAuthentication(clientContextProvider: clientContextProvider),
      DashboardFirebaseAuthentication(
        config: config,
        validator: firebaseJwtValidator,
        clientContextProvider: clientContextProvider,
        firestore: firestore,
      ),
    ]);
  }

  final _authenticationChain = <AuthenticationProvider>[];

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
    /// Walk through the providers
    for (final provider in _authenticationChain) {
      try {
        return await provider.authenticate(request);
      } on Unauthenticated {
        // nothing
      }
    }
    throw const Unauthenticated('User is not signed in');
  }
}

class DashboardFirebaseAuthentication implements AuthenticationProvider {
  DashboardFirebaseAuthentication({
    required Config config,
    required FirebaseJwtValidator validator,
    required FirestoreService firestore,
    ClientContextProvider clientContextProvider = Providers.serviceScopeContext,
  }) : _config = config,
       _validator = validator,
       _firestore = firestore,
       _clientContextProvider = clientContextProvider;

  /// The Cocoon config, guaranteed to be non-null.
  final Config _config;

  /// Provides the App Engine client context as part of the
  /// [AuthenticatedContext].
  ///
  /// This is guaranteed to be non-null.
  final ClientContextProvider _clientContextProvider;
  final FirestoreService _firestore;
  final FirebaseJwtValidator _validator;

  /// Attempt to validate a JWT as a Firebase token.
  ///
  /// NOTE: Until we fully switch over to Firebase; we could have a mix of JWT
  /// coming into cocoon. This should not be fatal.
  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    try {
      if (request.headers.value('X-Flutter-IdToken')
          case final idTokenFromHeader?) {
        final token = await _validator.decodeAndVerify(idTokenFromHeader);
        log.info('authed with firebase: ${token.email}');
        return authenticateFirebase(
          token,
          clientContext: _clientContextProvider(),
        );
      }
    } on JwtException {
      // do nothing while in transition
    }
    throw const Unauthenticated('Not a Firebase token');
  }

  @visibleForTesting
  Future<AuthenticatedContext> authenticateFirebase(
    TokenInfo token, {
    required ClientContext clientContext,
  }) async {
    if (token.email case final email?) {
      if (email.endsWith('@google.com') ||
          await _isAllowed(_config, token.email)) {
        return AuthenticatedContext(
          clientContext: clientContext,
          email: token.email!,
        );
      }
    }
    throw Unauthenticated(
      '${token.email} is not authorized to access the dashboard',
    );
  }

  Future<bool> _isAllowed(Config config, String? email) async {
    if (email == null) {
      return false;
    }
    final account = await Account.getByEmail(_firestore, email: email);
    return account != null;
  }
}

class DashboardCronAuthentication implements AuthenticationProvider {
  const DashboardCronAuthentication({
    ClientContextProvider clientContextProvider = Providers.serviceScopeContext,
  }) : _clientContextProvider = clientContextProvider;

  /// Provides the App Engine client context as part of the
  /// [AuthenticatedContext].
  ///
  /// This is guaranteed to be non-null.
  final ClientContextProvider _clientContextProvider;

  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    if (request.headers.value('X-Appengine-Cron') == 'true') {
      return AuthenticatedContext(
        clientContext: _clientContextProvider(),
        email: 'CRON_JOB',
      );
    }
    throw const Unauthenticated('Not a cron job');
  }
}
