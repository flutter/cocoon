// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/no_auth_request_handler.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:meta/meta.dart';

import 'request_handler_tester.dart';

class NoAuthRequestHandlerTester extends RequestHandlerTester {
  NoAuthRequestHandlerTester({super.request, Map<String, dynamic>? requestData})
    : requestData = requestData ?? <String, dynamic>{};

  Map<String, dynamic> requestData;

  @override
  @protected
  Future<T> run<T extends Body>(Future<T> Function() callback) {
    return super.run<T>(() {
      return runZoned<Future<T>>(
        () {
          return callback();
        },
        zoneValues: <RequestKey<dynamic>, Object>{
          NoAuthKey.requestData: requestData,
        },
      );
    });
  }
}
