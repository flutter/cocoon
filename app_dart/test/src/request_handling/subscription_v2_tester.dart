// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/luci/pubsub_message_v2.dart';
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler_v2.dart';
import 'package:meta/meta.dart';

import 'fake_authentication.dart';
import 'request_handler_tester.dart';

class SubscriptionV2Tester extends RequestHandlerTester {
  SubscriptionV2Tester({
    super.request,
    FakeAuthenticatedContext? context,
    PushMessageV2? message,
  })  : context = context ?? FakeAuthenticatedContext(),
        message = message ?? const PushMessageV2();

  FakeAuthenticatedContext context;
  PushMessageV2 message;

  @override
  @protected
  Future<T> run<T extends Body>(Future<T> Function() callback) {
    return super.run<T>(() {
      return runZoned<Future<T>>(
        () {
          return callback();
        },
        zoneValues: <RequestKey<dynamic>, Object>{
          ApiKey.authContext: context,
          PubSubKey.message: message,
        },
      );
    });
  }
}
