// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/typedefs.dart';
import 'package:googleapis/pubsub/v1.dart' as pubsub_api;
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../foundation/providers.dart';
import '../../request_handling/api_request_handler.dart';
import '../../service/logging.dart';

/// Pull subscription for waiting for commits to be available on Git-on-borg before scheduling.
///
/// The PubSub subscription is set up here:
/// https://cloud.google.com/cloudpubsub/subscription/detail/scheduler-gob-poller?project=flutter-dashboard&tab=overview
///
/// This endpoint acts as an intermediary queue from GitHub webhooks indiciating a PR has merged to the final scheduling of post-submit builds.
///
/// The template for the data of this subscription is:
/// ```dart
/// <String, Object>{
///   'Commit': $commitKey,
///   'BatchRequest': $batchRequest,
/// }
/// ```
/// Commit key contains the sha and branch.
@immutable
class GobPollerSubscription extends ApiRequestHandler {
  /// Creates a subscription for sending BuildBucket requests.
  const GobPollerSubscription({
    required Config config,
    required AuthenticationProvider authenticationProvider,
    required this.pubsub,
    this.httpClientProvider = Providers.freshHttpClient,
  }) : super(
          config: config,
          authenticationProvider: authenticationProvider,
        );

  final HttpClientProvider httpClientProvider;

  final PubSub pubsub;

  static const int kPullMesssageBatchSize = 25;

  @override
  Future<Body> get() async {
    // final pubsub_api.PullResponse pullResponse = await pubsub.pull('scheduler-poll-gob-sub', kPullMesssageBatchSize);
    if (pullResponse.receivedMessages == null) {
      log.fine('Received messages was null');
      return Body.empty;
    }

    for (pubsub_api.ReceivedMessage message in pullResponse.receivedMessages!) {}
    return Body.empty;
  }

  Future<void> _processMessage(pubsub_api.ReceivedMessage message) async {
    final Client httpClient = httpClientProvider();
  }
}
