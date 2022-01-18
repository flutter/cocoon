// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/luci/buildbucket.dart';
import '../../request_handling/subscription_handler.dart';

/// Subscription for making requests to BuildBucket.
///
/// The PubSub subscription is set up here:
/// https://cloud.google.com/cloudpubsub/subscription/detail/luci-postsubmit?project=flutter-dashboard&tab=overview
///
/// This endpoint is responsible for taking the load off other endpoints as buildbucket requests can
/// take a while and require
@immutable
class SchedulerRequest extends SubscriptionHandler {
  /// Creates a subscription for sending buildbucket requests.
  const SchedulerRequest(
    Config config,
    AuthenticationProvider authenticationProvider, {
    required this.buildBucketClient,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final BuildBucketClient buildBucketClient;

  static const String topicName = 'scheduler-requests';

  @override
  Future<Body> post() async {
    final String rawJson = (await message)!.data!;
    final Map<String, dynamic> json = jsonDecode(rawJson) as Map<String, dynamic>;
    final ScheduleBuildRequest request = ScheduleBuildRequest.fromJson(json);

    await buildBucketClient.scheduleBuild(request);
    return Body.empty;
  }
}
