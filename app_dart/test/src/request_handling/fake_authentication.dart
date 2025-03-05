// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/foundation/typedefs.dart';
import 'package:cocoon_service/src/model/appengine/key_helper.dart';
import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/config.dart';

// ignore: must_be_immutable
class FakeAuthenticationProvider implements AuthenticationProvider {
  FakeAuthenticationProvider({
    FakeClientContext? clientContext,
    this.authenticated = true,
  }) : clientContext = clientContext ?? FakeClientContext();

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
  Future<AuthenticatedContext> authenticateToken(
    TokenInfo token, {
    ClientContext? clientContext,
    Logging? log,
  }) async {
    if (authenticated) {
      return FakeAuthenticatedContext(
        clientContext: clientContext as FakeClientContext?,
      );
    } else {
      throw const Unauthenticated('Not authenticated');
    }
  }

  @override
  ClientContextProvider get clientContextProvider => throw UnimplementedError();

  @override
  Config get config => throw UnimplementedError();

  @override
  HttpClientProvider get httpClientProvider => throw UnimplementedError();

  @override
  Future<TokenInfo> tokenInfo(
    HttpRequest request, {
    Logging? log,
    String tokenType = 'id_token',
  }) async {
    return TokenInfo(email: 'abc@gmail.com', issued: DateTime.now());
  }
}

// ignore: must_be_immutable
class FakeAuthenticatedContext implements AuthenticatedContext {
  FakeAuthenticatedContext({FakeClientContext? clientContext})
    : clientContext = clientContext ?? FakeClientContext();

  @override
  FakeClientContext clientContext;
}

class FakeClientContext implements ClientContext {
  FakeClientContext({
    this.isDevelopmentEnvironment = true,
    this.isProductionEnvironment = false,
    FakeAppEngineContext? applicationContext,
  }) : applicationContext = applicationContext ?? FakeAppEngineContext();

  @override
  FakeAppEngineContext applicationContext;

  @override
  bool isDevelopmentEnvironment;

  @override
  bool isProductionEnvironment;

  @override
  late Services services;

  @override
  String? traceId;
}

class FakeAppEngineContext implements AppEngineContext {
  @override
  String applicationID = 'flutter-dashboard';

  @override
  late String fullQualifiedApplicationId;

  @override
  late String instance;

  @override
  String? instanceId;

  @override
  late bool isDevelopmentEnvironment;

  @override
  late String module;

  @override
  String partition = '[default]';

  @override
  late String version;
}

class FakeKeyHelper extends KeyHelper {
  FakeKeyHelper({AppEngineContext? applicationContext})
    : super(applicationContext: applicationContext ?? FakeAppEngineContext());
}
