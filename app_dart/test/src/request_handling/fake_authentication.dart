// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:appengine/appengine.dart';

// ignore: must_be_immutable
class FakeAuthenticationProvider implements AuthenticationProvider {
  FakeAuthenticationProvider({
    this.agent,
    ClientContext clientContext,
    this.config,
  }) : clientContext = clientContext ?? FakeClientContext();

  Agent agent;
  ClientContext clientContext;

  @override
  Config config;

  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
    return FakeAuthenticatedContext(agent: agent, clientContext: clientContext);
  }

  @override
  ClientContextProvider get clientContextProvider => () => clientContext;
}

// ignore: must_be_immutable
class FakeAuthenticatedContext implements AuthenticatedContext {
  FakeAuthenticatedContext({
    this.agent,
    ClientContext clientContext,
  }) : clientContext = clientContext ?? FakeClientContext();

  @override
  Agent agent;

  @override
  ClientContext clientContext;
}

class FakeClientContext implements ClientContext {
  @override
  AppEngineContext applicationContext;

  @override
  bool isDevelopmentEnvironment = false;

  @override
  bool isProductionEnvironment = true;

  @override
  Services services;

  @override
  String traceId;
}
