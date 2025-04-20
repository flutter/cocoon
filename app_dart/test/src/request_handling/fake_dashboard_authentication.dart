// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/dashboard_authentication.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';

// ignore: must_be_immutable
class FakeDashboardAuthentication implements DashboardAuthentication {
  FakeDashboardAuthentication({
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
}

// ignore: must_be_immutable
class FakeAuthenticatedContext implements AuthenticatedContext {
  FakeAuthenticatedContext({FakeClientContext? clientContext})
    : clientContext = clientContext ?? FakeClientContext();

  @override
  FakeClientContext clientContext;

  @override
  String email = 'fake@example.com';
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
