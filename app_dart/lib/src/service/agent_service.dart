// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:dbcrypt/dbcrypt.dart';
import 'package:meta/meta.dart';

/// Service class for Agent.
///
/// This service exists to provide common agent queries made by
/// the Cocoon backend.
@immutable
class AgentService {
  /// Generate new authorization token for [agent]
  ///
  /// The hashed code of token will be returned as a list
  List<int> refreshAgentAuthToken() {
    const int length = 16;
    const String urlSafeChars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    final Random random = Random();
    final StringBuffer token = StringBuffer();

    for (int i = 0; i < length; i++) {
      token.write(urlSafeChars[random.nextInt(urlSafeChars.length)]);
    }

    final String hashToken =
        DBCrypt().hashpw(token.toString(), DBCrypt().gensalt());

    return ascii.encode(hashToken);
  }
}
