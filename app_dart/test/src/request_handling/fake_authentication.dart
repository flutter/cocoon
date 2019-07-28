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
    ClientContext clientContext,
    this.authenticated = true,
  })  : assert(authenticated != null),
        clientContext = clientContext ?? FakeClientContext();

  bool authenticated;
  Agent agent;
  ClientContext clientContext;

  @override
  Future<AuthenticatedContext> authenticate(HttpRequest request) async {
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
  bool isDevelopmentEnvironment = true;

  @override
  bool isProductionEnvironment = false;

  @override
  Services services;

  @override
  String traceId;
}
