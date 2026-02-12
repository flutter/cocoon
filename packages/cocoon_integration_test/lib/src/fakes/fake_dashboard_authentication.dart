// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
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
  Future<AuthenticatedContext> authenticate(Request request) async {
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
  FakeClientContext({this.isDevelopmentEnvironment = true});

  @override
  bool isDevelopmentEnvironment;
}
