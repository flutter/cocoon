// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:meta/meta.dart';

import '../model/luci/push_message.dart';
import '../service/config.dart';
import '../service/logging.dart';
import 'api_request_handler.dart';
import 'authentication.dart';
import 'body.dart';

/// An [ApiRequestHandler] that handles PubSub subscription messages.
///
/// Messages adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
///  * Request body is passed following the format of [PushMessageEnvelope].
@immutable
abstract class SubscriptionHandler extends ApiRequestHandler<Body> {
  /// Creates a new [SubscriptionHandler].
  const SubscriptionHandler({
    required Config config,
    required AuthenticationProvider authenticationProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  Future<String> get _requestString async {
    final String requestString = String.fromCharCodes(requestBody!);
    log.fine(requestString);
    return requestString;
  }

  /// Raw message from [requestBody].
  Future<PushMessageEnvelope> get _envelope async =>
      PushMessageEnvelope.fromJson(json.decode(await _requestString) as Map<String, dynamic>);

  /// Pubsub message from [requestBody].
  Future<PushMessage?> get message async => (await _envelope).message;
}
