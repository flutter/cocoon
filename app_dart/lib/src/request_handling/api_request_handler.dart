// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import 'authentication.dart';
import 'exceptions.dart';
import 'http_utils.dart';
import 'public_api_request_handler.dart';
import 'request_handler.dart';

/// A [RequestHandler] that handles API requests.
///
/// API requests adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
abstract base class ApiRequestHandler extends PublicApiRequestHandler {
  /// Creates a new [ApiRequestHandler].
  const ApiRequestHandler({
    required super.config,
    required this.authenticationProvider,
  });

  /// Service responsible for authenticating this [HttpRequest].
  @protected
  final AuthenticationProvider authenticationProvider;

  /// The authentication context associated with the HTTP request.
  ///
  /// This is guaranteed to be non-null. If the request was unauthenticated,
  /// the request will be denied.
  @protected
  AuthenticatedContext? get authContext =>
      getValue<AuthenticatedContext>(ApiKey.authContext);

  @override
  Future<void> service(
    Request request, {
    Future<void> Function(HttpStatusException)? onError,
  }) async {
    AuthenticatedContext context;
    try {
      context = await authenticationProvider.authenticate(request);
    } on Unauthenticated catch (error) {
      final response = request.response;
      response.statusCode = HttpStatus.unauthorized;
      await response.addStream(Stream.value(utf8.encode(error.message)));
      await response.flush();
      await response.close();
      return;
    }

    await runZoned<Future<void>>(() async {
      await super.service(request);
    }, zoneValues: <ApiKey<dynamic>, Object?>{ApiKey.authContext: context});
  }

  /// Checks whether the current user has write permissions to the specified
  /// repository.
  ///
  /// If the user is authenticated via a @google.com account, they are assumed
  /// to have write access.
  ///
  /// Otherwise, if the user is authenticated via GitHub, their permissions are
  /// checked via the GitHub API.
  ///
  /// Throws [Forbidden] if the user does not have write access.
  Future<void> checkWritePermissions(RepositorySlug slug) async {
    if (isUserGoogleEmployee) {
      return;
    }
    if (await hasUserGithubWritePermission(slug)) {
      return;
    }
    throw Forbidden(
      'User ${authContext!.githubLogin ?? authContext!.email} does not have write access to ${slug.fullName}',
    );
  }

  /// Whether the current user is a Google employee (authenticated via @google.com).
  bool get isUserGoogleEmployee => authContext!.email.endsWith('@google.com');

  /// Whether the current user has write permissions to the specified
  /// repository via GitHub.
  Future<bool> hasUserGithubWritePermission(RepositorySlug slug) async {
    final githubLogin = authContext!.githubLogin;
    if (githubLogin == null) {
      return false;
    }
    final githubService = await config.createGithubService(slug);
    return githubService.hasUserWritePermissions(slug, githubLogin);
  }
}

class ApiKey<T> extends RequestKey<T> {
  const ApiKey._(super.name);

  static const ApiKey<AuthenticatedContext> authContext =
      ApiKey<AuthenticatedContext>._('authenticatedContext');
  static const ApiKey<Map<String, dynamic>> requestData =
      ApiKey<Map<String, dynamic>>._('requestData');
}
