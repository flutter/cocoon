// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import 'exceptions.dart';

/// Class capable of authenticating [HttpRequest]s using [serviceAccount].
///
/// If the request has [HttpHeaders.authorizationHeader], the token
/// will be authenticated as a service account. This token is validated against
/// Google Auth APIs  to be authenticated for [serviceAccount].
///
/// Otherwise, the request throws an [Unauthenticated] exception.
@immutable
class ServiceAccountAuthenticationProvider extends AuthenticationProvider {
  const ServiceAccountAuthenticationProvider(
    Config config,
    this.serviceAccount, {
    ClientContextProvider clientContextProvider = Providers.serviceScopeContext,
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
    LoggingProvider loggingProvider = Providers.serviceScopeLogger,
  }) : super(
          config,
          clientContextProvider: clientContextProvider,
          httpClientProvider: httpClientProvider,
          loggingProvider: loggingProvider,
        );

  final String serviceAccount;

  /// Authenticates the specified [request] and returns the associated [AuthenticatedContext].
  ///
  /// This will throw an [Unauthenticated] exception if the request is unauthenticated.
  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    final String idToken = request.headers.value(HttpHeaders.authorizationHeader);

    final ClientContext clientContext = clientContextProvider();
    final Logging log = loggingProvider();

    if (idToken != null) {
      log.debug('Authenticating with service account $serviceAccount');
      return await authenticateIdToken(
        idToken,
        clientContext: clientContext,
        log: log,
        expectedAccount: serviceAccount,
      );
    }

    throw const Unauthenticated('No authorization header passed');
  }
}
