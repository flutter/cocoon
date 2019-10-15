// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:dbcrypt/dbcrypt.dart';
import 'package:meta/meta.dart';

typedef AgentServiceProvider = AgentService Function();

/// Service class for Agent.
///
/// This service provides funtionality for interacting with
/// [Agent] instances
@immutable
class AgentService {
  /// Generate new authorization token for [agent]
  ///
  /// The hashed code of token will be returned as a list
  const AgentService();

  static AgentService defaultProvider() {
    return const AgentService();
  }

  AgentAuthToken refreshAgentAuthToken() {
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

    return AgentAuthToken(token.toString(), ascii.encode(hashToken));
  }
}

class AgentAuthToken {
  const AgentAuthToken(this.value, this.hash)
      : assert(value != null),
        assert(hash != null);

  final String value;
  final List<int> hash;
}
