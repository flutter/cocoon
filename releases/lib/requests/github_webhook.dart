// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../common/handler.dart';
import '../service/log.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook extends Handler {
  const GithubWebhook() : super('webhook');

  @override
  Future<Response> post(Context context, Request request) async {
    log.info(request);
    return Response.ok(null);
  }
}
