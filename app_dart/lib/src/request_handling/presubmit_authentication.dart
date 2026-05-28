// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

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
    final githubLogin = await _getGithubLoginCached(
      token.firebase?.identities?['github.com']?.first,
    );
    if (await _isGithubAllowedCached(
      token.firebase?.identities?['github.com']?.first,
      githubLogin,
    )) {
      return AuthenticatedContext(
        clientContext: clientContext,
        email: token.email!,
        githubLogin: githubLogin,
      );
    }
    throw Unauthenticated(
      '${token.email} is not authorized to access the checkrun',
    );
  }

  Future<String?> _getGithubLogin(String? accountId) async {
    if (accountId == null) {
      return null;
    }
    final ghService = _config.createGithubServiceWithToken(
      await _config.githubOAuthToken,
    );
    final user = await ghService.getUserByAccountId(accountId);
    return user.login;
  }

  Future<String?> _getGithubLoginCached(String? accountId) async {
    final bytes = await _cache.getOrCreateWithLocking(
      'github_account_login',
      accountId ?? 'null_accountId',
      createFn: () async => Uint8List.fromList(
        (await _getGithubLogin(accountId))?.codeUnits ?? [],
      ),
    );
    final login = String.fromCharCodes(bytes!);
    return login.isEmpty ? null : login;
  }

  Future<bool> _isGithubAllowed(String? accountId, String? githubLogin) async {
    final login = githubLogin ?? await _getGithubLogin(accountId);
    if (login == null) {
      return false;
    }
    final ghService = _config.createGithubServiceWithToken(
      await _config.githubOAuthToken,
    );
    return await ghService.hasUserWritePermissions(
      RepositorySlug('flutter', 'flutter'),
      login,
    );
  }

  Future<bool> _isGithubAllowedCached(
    String? accountId,
    String? githubLogin,
  ) async {
    final bytes = await _cache.getOrCreateWithLocking(
      'github_account_allowed',
      accountId ?? 'null_accountId',
      createFn: () async =>
          (await _isGithubAllowed(accountId, githubLogin)).toUint8List(),
    );
    return bytes?.toBool() ?? false;
  }
}
