// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler.dart';
import 'package:gcloud/pubsub.dart';
import 'package:meta/meta.dart';

import 'fake_authentication.dart';
import 'request_handler_tester.dart';

class SubscriptionV2Tester extends RequestHandlerTester {

  static const String _fakePubsubMessage = '''
    {
      "build": {
        "id": "1",
        "builder": {
          "project": "flutter",
          "bucket": "try",
          "builder": "Windows Engine Drone"
        }
      }
    }
  ''';

  SubscriptionV2Tester({
    super.request,
    FakeAuthenticatedContext? context,
    Message? message,
  }) : context = context ?? FakeAuthenticatedContext();

  FakeAuthenticatedContext context;
  Message message = Message.withString(_fakePubsubMessage);

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
