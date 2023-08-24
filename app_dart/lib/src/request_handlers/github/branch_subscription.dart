// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:github/hooks.dart';
import 'package:meta/meta.dart';

import '../../../protos.dart' as pb;
import '../../request_handling/body.dart';
import '../../request_handling/subscription_handler.dart';
import '../../service/branch_service.dart';
import '../../service/logging.dart';

const String kWebhookCreateEvent = 'create';

/// Subscription for processing GitHub webhooks relating to branches.
///
/// This subscription processes branch events on GitHub into Cocoon.
@immutable
class GithubBranchWebhookSubscription extends SubscriptionHandler {
  /// Creates a subscription for processing GitHub webhooks.
  const GithubBranchWebhookSubscription({
    required super.cache,
    required super.config,
    required this.branchService,
    required this.commitService,
  }) : super(subscriptionName: 'github-webhook-branches');

  final BranchService branchService;
  final CommitService commitService;

  @override
  Future<Body> post() async {
    if (message.data == null || message.data!.isEmpty) {
      log.warning('GitHub webhook message was empty. No-oping');
      return Body.empty;
    }

    final pb.GithubWebhookMessage webhook = pb.GithubWebhookMessage.fromJson(message.data!);
    if (webhook.event != kWebhookCreateEvent) {
      log.fine('Github event is not a "create" event, so this event will not be processed');
      return Body.empty;
    }

    log.fine('Processing ${webhook.event}');
    final CreateEvent createEvent = CreateEvent.fromJson(json.decode(webhook.payload) as Map<String, dynamic>);
    log.fine('Handling create request for branch ${createEvent.ref}');
    await branchService.handleCreateRequest(createEvent);

    final RegExp candidateBranchRegex = RegExp(r'flutter-\d+\.\d+-candidate\.\d+');
    if (candidateBranchRegex.hasMatch(createEvent.ref!)) {
      log.fine('Branch ${createEvent.ref} is a candidate branch, creating new commit in the datastore');
      await commitService.handleCreateGithubRequest(createEvent);
    }

    return Body.empty;
  }
}
