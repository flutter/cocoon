// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/authentication.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';

import 'fake_authentication.dart';
import 'fake_http.dart';

class ApiRequestHandlerTester {
  ApiRequestHandlerTester({
    this.request,
    HttpResponse response,
    AuthenticatedContext context,
    this.requestData = const <String, dynamic>{},
  })  : response = response ?? FakeHttpResponse(),
        context = context ?? FakeAuthenticatedContext();

  HttpRequest request;
  HttpResponse response;
  AuthenticatedContext context;
  Map<String, dynamic> requestData;

  Future<T> get<T extends Body>(ApiRequestHandler<T> handler) {
    return _run<T>(() {
      return handler.get(); // ignore: invalid_use_of_protected_member
    });
  }

  Future<T> post<T extends Body>(ApiRequestHandler<T> handler) {
    return _run<T>(() {
      return handler.post(); // ignore: invalid_use_of_protected_member
    });
  }

  Future<T> _run<T extends Body>(Future<T> callback()) {
    return runZoned<Future<T>>(() {
      return callback();
    }, zoneValues: <RequestKey<dynamic>, Object>{
      RequestKey.request: request,
      RequestKey.response: response,
      ApiKey.authContext: context,
      ApiKey.requestData: requestData,
    });
  }
}
