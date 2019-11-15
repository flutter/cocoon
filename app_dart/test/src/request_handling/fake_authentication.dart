// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:appengine/appengine.dart';

// ignore: must_be_immutable
class FakeAuthenticationProvider implements AuthenticationProvider {
  FakeAuthenticationProvider({
    this.agent,
    FakeClientContext clientContext,
    this.authenticated = true,
  })  : assert(authenticated != null),
        clientContext = clientContext ?? FakeClientContext();

  bool authenticated;
  Agent agent;
  FakeClientContext clientContext;

  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    if (authenticated) {
      return FakeAuthenticatedContext(agent: agent, clientContext: clientContext);
    } else {
      throw const Unauthenticated('Not authenticated');
    }
  }

  @override
  Future<AuthenticatedContext> authenticateIdToken(String idToken, {ClientContext clientContext, Logging log}) async {
    if (authenticated) {
      return FakeAuthenticatedContext(agent: agent, clientContext: clientContext);
    } else {
      throw const Unauthenticated('Not authenticated');
    }
  }
}

// ignore: must_be_immutable
class FakeAuthenticatedContext implements AuthenticatedContext {
  FakeAuthenticatedContext({
    this.agent,
    FakeClientContext clientContext,
  }) : clientContext = clientContext ?? FakeClientContext();

  @override
  Agent agent;

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
