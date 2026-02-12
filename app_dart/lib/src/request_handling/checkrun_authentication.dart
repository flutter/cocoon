// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/google/token_info.dart';
import '../service/firebase_jwt_validator.dart';
import 'exceptions.dart';

/// Class capable of authenticating [Request]s from the Checkrun page.
///
/// There are two types of authentication this class supports:
///
///  1. If the request has the `'X-Flutter-IdToken'` HTTP header
///     set to a valid encrypted JWT token, then the request will be authenticated
///     as a user account.
///
///     @google.com accounts can call APIs using curl and gcloud.
///     E.g. curl '<api_url>' -H "X-Flutter-IdToken: $(gcloud auth print-identity-token)"
///
///     User accounts are only authorized if the user is either a "@google.com"
///     account or is an [AllowedAccount] in Cocoon's Firestore.
///
/// 2. If the request has github.com token, then the request will be authenticated
///    as a GitHub user account.
///
/// If none of the above authentication methods yield an authenticated
/// request, then the request is unauthenticated, and any call to
/// [authenticate] will throw an [Unauthenticated] exception.
///
/// See also:
///
///  * <https://cloud.google.com/appengine/docs/standard/python/reference/request-response-headers>
@immutable
interface class CheckrunAuthentication implements AuthenticationProvider {
  CheckrunAuthentication({
    required CacheService cache,
    required Config config,
    required FirebaseJwtValidator firebaseJwtValidator,
    required FirestoreService firestore,
    ClientContextProvider clientContextProvider = Providers.serviceScopeContext,
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
  }) {
    _authenticationChain.addAll([
      DashboardFirebaseAuthentication(
        cache: cache,
        validator: firebaseJwtValidator,
        clientContextProvider: clientContextProvider,
        firestore: firestore,
      ),
      GithubAuthentication(
        cache: cache,
        config: config,
        validator: firebaseJwtValidator,
        clientContextProvider: clientContextProvider,
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
  Future<AuthenticatedContext> authenticate(Request request) async {
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

/// Class capable of authenticating [Request]s from the Checkrun page.
class GithubAuthentication implements AuthenticationProvider {
  GithubAuthentication({
    required CacheService cache,
    required Config config,
    required FirebaseJwtValidator validator,
    ClientContext Function() clientContextProvider =
        Providers.serviceScopeContext,
  }) : _cache = cache,
       _config = config,
       _validator = validator,
       _clientContextProvider = clientContextProvider;

  final CacheService _cache;

  /// The Cocoon config, guaranteed to be non-null.
  final Config _config;

  /// Provides the App Engine client context as part of the
  /// [AuthenticatedContext].
  ///
  /// This is guaranteed to be non-null.
  final ClientContextProvider _clientContextProvider;
  final FirebaseJwtValidator _validator;

  /// Attempt to validate a JWT as a Firebase token.
  /// And then validate whether the token has flutter repo write permissions.
  @override
  Future<AuthenticatedContext> authenticate(Request request) async {
    try {
      if (request.header('X-Flutter-IdToken') case final idTokenFromHeader?) {
        final token = await _validator.decodeAndVerify(idTokenFromHeader);
        log.info('authing with github.com');
        return authenticateGithub(
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
  Future<AuthenticatedContext> authenticateGithub(
    TokenInfo token, {
    required ClientContext clientContext,
  }) async {
    if (await _isGithubAllowedCached(
      token.firebase?.identities?['github.com']?.first,
    )) {
      return AuthenticatedContext(
        clientContext: clientContext,
        email: token.email!,
      );
    }
    throw Unauthenticated(
      '${token.email} is not authorized to access the checkrun',
    );
  }

  Future<bool> _isGithubAllowed(String? accountId) async {
    if (accountId == null) {
      return false;
    }
    final ghService = _config.createGithubServiceWithToken(
      await _config.githubOAuthToken,
    );
    final user = await ghService.getUserByAccountId(accountId);
    if (user.login == null) {
      return false;
    }
    return await ghService.hasUserWritePermissions(
      RepositorySlug('flutter', 'flutter'),
      user.login!,
    );
  }

  Future<bool> _isGithubAllowedCached(String? accountId) async {
    final bytes = await _cache.getOrCreateWithLocking(
      'github_account_allowed',
      accountId ?? 'null_accountId',
      createFn: () async => (await _isGithubAllowed(accountId)).toUint8List(),
    );
    return bytes?.toBool() ?? false;
  }
}
