// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:meta/meta.dart';

import 'exceptions.dart';

@immutable
abstract interface class AuthenticationProvider {
  /// Authenticates the specified [request] and returns the associated
  /// [AuthenticatedContext].
  ///
  /// See the class documentation on [AuthenticationProvider] for a discussion
  /// of the different types of authentication that are accepted.
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  Future<AuthenticatedContext> authenticate(HttpRequest request);

  /// Gets oauth token information. This method requires the token to be stored in
  /// X-Flutter-IdToken header.
  // Future<TokenInfo> tokenInfo(
  //   HttpRequest request, {
  //   String tokenType = 'id_token',
  // }) async {
  //   final idTokenFromHeader = request.headers.value('X-Flutter-IdToken');
  //   final client = httpClientProvider();
  //   try {
  //     final verifyTokenResponse = await client.get(
  //       Uri.https('oauth2.googleapis.com', '/tokeninfo', <String, String?>{
  //         tokenType: idTokenFromHeader,
  //       }),
  //     );

  //     if (verifyTokenResponse.statusCode != HttpStatus.ok) {
  //       /// Google Auth API returns a message in the response body explaining why
  //       /// the request failed. Such as "Invalid Token".
  //       log.debug(
  //         'Token verification failed: ${verifyTokenResponse.statusCode}; '
  //         '${verifyTokenResponse.body}',
  //       );
  //       throw const Unauthenticated('Invalid ID token');
  //     }

  //     try {
  //       return TokenInfo.fromJson(
  //         json.decode(verifyTokenResponse.body) as Map<String, dynamic>,
  //       );
  //     } on FormatException {
  //       throw InternalServerError(
  //         'Invalid JSON: "${verifyTokenResponse.body}"',
  //       );
  //     }
  //   } finally {
  //     client.close();
  //   }
  // }
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
    required this.email,
  });

  /// The App Engine [ClientContext] of the current request.
  ///
  /// This is guaranteed to be non-null.
  final ClientContext clientContext;

  /// The email address associated with this authenticated context.
  final String email; // maybe TokenInfo
}
