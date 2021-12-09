// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:meta/meta.dart';

import 'fake_authentication.dart';
import 'fake_http.dart';
import 'request_handler_tester.dart';

class SubscriptionTester extends RequestHandlerTester {
  SubscriptionTester({
    FakeHttpRequest? request,
    FakeAuthenticatedContext? context,
    this.message = '{}',
  })  : context = context ?? FakeAuthenticatedContext(),
        super(request: request);

  FakeAuthenticatedContext context;
  String message;

  @override
  @protected
  Future<T> run<T extends Body>(Future<T> callback()) {
    return super.run<T>(() {
      return runZoned<Future<T>>(() {
        return callback();
      }, zoneValues: <RequestKey<dynamic>, Object>{
        ApiKey.authContext: context,
        ApiKey.requestBody: Uint8List.fromList(message.codeUnits),
      });
    });
  }
}
