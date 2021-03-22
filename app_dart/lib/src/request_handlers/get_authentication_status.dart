// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';

@immutable
class GetAuthenticationStatus extends RequestHandler<Body> {
  const GetAuthenticationStatus(
    Config config,
    this.authenticationProvider,
  ) : super(config: config);

  final AuthenticationProvider authenticationProvider;

  @override
  Future<Body> get() async {
    try {
      await authenticationProvider.authenticate(request);
      return Body.forJson(const <String, dynamic>{'Status': 'OK'});
    } on Unauthenticated {
      return Body.forJson(const <String, dynamic>{'Status': 'Unauthorized'});
    }
  }
}
