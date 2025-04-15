// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';

import '../../cocoon_service.dart';
import '../model/github/annotations.dart';
import '../model/github/workflow_job.dart';

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

  static final _validSha = RegExp(r'^[0-9a-f]{40}$');

  /// Locates the contnet aware hash for [workflow] or null.
  ///
  /// This should only be used for workflow events in the merge group.
  Future<String?> hashFromWorkflowJobEvent(WorkflowJobEvent workflow) async {
    // Step 1: Perform a very conservative validation
    // We've triggered a workflow from a dispatch workflow event.
    // We want to make sure we're only looking at CAH values from:
    //   cocoon, merge groups, finished successfully, flutter/flutter.
    if (workflow.action != 'completed') return null;
    final workflowJob = workflow.workflowJob;
    if (workflowJob == null) return null;
    if (workflow.repository?.fullName != 'flutter/flutter') return null;
    if (workflowJob.name != 'generate-engine-content-hash' ||
        workflowJob.status != 'completed' ||
        workflowJob.conclusion != 'success' ||
        workflowJob.workflowName !=
            'Generate a content aware hash for the Flutter Engine' ||
        Uri.tryParse(workflowJob.checkRunUrl ?? '') == null ||
        !_validSha.hasMatch(workflowJob.headSha ?? '') ||
        !tryParseGitHubMergeQueueBranch(workflowJob.headBranch ?? '').parsed) {
      return null;
    }
    if (workflow.sender?.login != 'fluttergithubbot') {
      log.warn('Workflow Job Sender unexpected: ${workflow.sender?.login}');
      return null;
    }

    // Step 2: Download the annotations
    final gh = await _config.createGithubService(
      RepositorySlug.full('flutter/flutter'),
    );
    final response = await gh.github.request(
      'GET',
      '${workflowJob.checkRunUrl}/annotations',
    );
    if (response.statusCode != 200) return null;

    // Step 3: Find the correct annotation.
    final List<dynamic> data;
    try {
      data = json.decode(response.body) as List<dynamic>;
    } catch (e) {
      log.debug('error decoding annotation json: ${response.body}', e);
      return null;
    }
    final annotations = Annotation.fromJsonList(data);
    for (final annotation in annotations) {
      if (annotation.message == null) continue;
      try {
        final message = json.decode(annotation.message!);
        if (message case {'engine_content_hash': final String hash}) {
          if (_validSha.hasMatch(hash)) {
            log.debug('content_aware_hash = $hash');
            // Success!
            return hash;
          }
        }
      } catch (_) {}
    }

    // Fail
    return null;
  }
}
