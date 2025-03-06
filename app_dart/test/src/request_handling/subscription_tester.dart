// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler.dart';
import 'package:meta/meta.dart';

import 'fake_authentication.dart';
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
