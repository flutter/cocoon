// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/subscription_handler.dart';
import '../service/logging.dart';

/// An endpoint for listening to build updates for dart-internal builds and
/// saving the results to the datastore.
///
/// The PubSub subscription is available here:
/// https://pantheon.corp.google.com/cloudpubsub/subscription/detail/dart-internal-build-results-sub?project=flutter-dashboard
@immutable
class DartInternalSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to dart-internal build results.
  const DartInternalSubscription({
    required super.cache,
    required super.config,
    super.authProvider,
  }) : super(subscriptionName: 'dart-internal-build-results-sub');

  @override
  Future<Body> post() async {
    log.fine('Consumed message: ${message.data}');

    return Body.empty;
  }
}
