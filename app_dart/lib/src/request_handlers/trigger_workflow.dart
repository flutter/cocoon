// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';

@immutable
class TriggerWorkflow extends ApiRequestHandler<Body> {
  const TriggerWorkflow({
    required super.config,
    required super.authenticationProvider,
  });

  static const String refParam = 'ref';
  // Intentionally kept at 'engine' as there may be scripts out there.
  static const String workflowParam = 'workflow';

  @override
  Future<Body> post() async {
    // auth already happened; grab the query parameters.
    checkRequiredQueryParameters([refParam, workflowParam]);
    final ref = request!.uri.queryParameters[refParam]!;
    final workflow = request!.uri.queryParameters[workflowParam]!;
    await triggerWorkflow(ref, workflow);
    return Body.empty;
  }

  Future triggerWorkflow(String ref, String workflow) async {
    // Use this specific token to trigger the workflow.
    final gh = config.createGitHubClientWithToken(
      await config.githubOAuthToken,
    );

    // The external package has no API for this:
    // https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event
    //
    // Also: we need to call `request` directly because the body is empty.
    final response = await gh.request(
      'POST',
      '/repos/flutter/flutter/actions/workflows/$workflow/dispatches',
      body: json.encode({'ref': ref}),
    );
    if (response.statusCode != 204 || response.body.isNotEmpty) {
      log.warning(
        'trigger-workflow($ref, $workflow): failed; ${response.statusCode} / ${response.body}',
      );
    }
  }
}
