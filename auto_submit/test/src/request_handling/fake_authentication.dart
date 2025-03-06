// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/request_handling/authentication.dart';
import 'package:auto_submit/requests/exceptions.dart';
import 'package:shelf/shelf.dart';

// ignore: must_be_immutable
class FakeCronAuthProvider implements CronAuthProvider {
  FakeCronAuthProvider({this.authenticated = true});

  bool authenticated;

  @override
  Future<bool> authenticate(Request request) async {
    if (authenticated) {
      return true;
    } else {
      throw const Unauthenticated('Not authenticated');
    }
  }
}
