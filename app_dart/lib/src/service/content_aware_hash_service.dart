// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';

import 'config.dart' show Config;

enum ContentHashWorkflowStatus { ok, error }

/// Requests GitHub to run the content-aware-hash workflow for a requests REF
interface class ContentAwareHashService {
  ContentAwareHashService({required Config config}) : _config = config;

  /// The global configuration of this AppEngine server.
  final Config _config;

  /// Trigger
  Future<ContentHashWorkflowStatus> triggerWorkflow(String gitRef) async {
    // Use this specific token to trigger the workflow.
    final gh = _config.createGitHubClientWithToken(
      await _config.githubOAuthToken,
    );

    // The external package has no API for this:
    // https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event
    //
    // Also: we need to call `request` directly because the body is empty.
    final response = await gh.request(
      'POST',
      '/repos/flutter/flutter/actions/workflows/content-aware-hash.yml/dispatches',
      body: json.encode({'ref': gitRef}),
    );
    if (response.statusCode != 204 || response.body.isNotEmpty) {
      log.warn(
        '$ContentAwareHashService.triggerWorkflow($gitRef): failed; '
        '${response.statusCode} / '
        '${response.body}',
      );
      return ContentHashWorkflowStatus.error;
    }
    return ContentHashWorkflowStatus.ok;
  }
}
