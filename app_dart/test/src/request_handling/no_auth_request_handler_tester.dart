// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/no_auth_request_handler.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:meta/meta.dart';

import 'fake_logging.dart';
import 'request_handler_tester.dart';

class NoAuthRequestHandlerTester extends RequestHandlerTester {
  NoAuthRequestHandlerTester({
    HttpRequest request,
    FakeLogging log,
    Map<String, dynamic> requestData,
  })  : requestData = requestData ?? <String, dynamic>{},
        super(request: request, log: log);

  Map<String, dynamic> requestData;

  @override
  @protected
  Future<T> run<T extends Body>(Future<T> callback()) {
    return super.run<T>(() {
      return runZoned<Future<T>>(() {
        return callback();
      }, zoneValues: <RequestKey<dynamic>, Object>{
        NoAuthKey.requestData: requestData,
      });
    });
  }
}
