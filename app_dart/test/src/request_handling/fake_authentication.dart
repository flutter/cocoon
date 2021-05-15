// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/foundation/typedefs.dart';
import 'package:cocoon_service/src/model/appengine/key_helper.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:gcloud/db.dart';

// ignore: must_be_immutable
class FakeAuthenticationProvider implements AuthenticationProvider {
  FakeAuthenticationProvider({
    FakeClientContext clientContext,
    this.authenticated = true,
  })  : assert(authenticated != null),
        clientContext = clientContext ?? FakeClientContext();

  bool authenticated;
  FakeClientContext clientContext;

  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    if (authenticated) {
      return FakeAuthenticatedContext(clientContext: clientContext);
    } else {
      throw const Unauthenticated('Not authenticated');
    }
  }

  @override
  Future<AuthenticatedContext> authenticateIdToken(
    String idToken, {
    ClientContext clientContext,
    Logging log,
    String expectedAccount,
  }) async {
    if (authenticated) {
      return FakeAuthenticatedContext(clientContext: clientContext as FakeClientContext);
    } else {
      throw const Unauthenticated('Not authenticated');
    }
  }

  @override
  bool compareHashAndPassword(List<int> serverAuthTokenHash, String clientAuthToken) {
    throw UnimplementedError();
  }

  @override
  ClientContextProvider get clientContextProvider => throw UnimplementedError();

  @override
  Config get config => throw UnimplementedError();

  @override
  HttpClientProvider get httpClientProvider => throw UnimplementedError();

  @override
  LoggingProvider get loggingProvider => throw UnimplementedError();
}

// ignore: must_be_immutable
class FakeAuthenticatedContext implements AuthenticatedContext {
  FakeAuthenticatedContext({
    FakeClientContext clientContext,
  }) : clientContext = clientContext ?? FakeClientContext();

  @override
  FakeClientContext clientContext;
}

class FakeClientContext implements ClientContext {
  FakeClientContext({
    this.isDevelopmentEnvironment = true,
    this.isProductionEnvironment = false,
    FakeAppEngineContext applicationContext,
  }) : applicationContext = applicationContext ?? FakeAppEngineContext();

  @override
  FakeAppEngineContext applicationContext;

  @override
  bool isDevelopmentEnvironment;

  @override
  bool isProductionEnvironment;

  @override
  Services services;

  @override
  String traceId;
}

class FakeAppEngineContext implements AppEngineContext {
  @override
  String applicationID;

  @override
  String fullQualifiedApplicationId;

  @override
  String instance;

  @override
  String instanceId;

  @override
  bool isDevelopmentEnvironment;

  @override
  String module;

  @override
  String partition;

  @override
  String version;
}

class FakeKeyHelper extends KeyHelper {
  FakeKeyHelper({
    AppEngineContext applicationContext,
  }) : super(applicationContext: applicationContext);

  @override
  String encode(Key<dynamic> key) {
    return '';
  }
}
