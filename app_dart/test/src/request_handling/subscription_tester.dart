// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/luci/pubsub_message.dart';

import 'fake_dashboard_authentication.dart';
import 'request_handler_tester.dart';

class SubscriptionTester extends RequestHandlerTester {
  SubscriptionTester({
    super.request,
    FakeAuthenticatedContext? context,
    PushMessage? message,
  }) : context = context ?? FakeAuthenticatedContext(),
       message = message ?? const PushMessage();

  FakeAuthenticatedContext context;
  PushMessage message;
}
