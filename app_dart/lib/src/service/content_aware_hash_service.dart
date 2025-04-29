// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../model/firestore/content_aware_hash_builds.dart'
    show BuildStatus, ContentAwareHashBuilds;
import '../model/github/annotations.dart';
import '../model/github/workflow_job.dart';

enum ContentHashWorkflowStatus { ok, error }

/// Requests GitHub to run the content-aware-hash workflow for a requests REF
interface class ContentAwareHashService {
  ContentAwareHashService({
    required Config config,
    required FirestoreService firestore,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _config = config,
       _firestore = firestore,
       _now = now;

  /// The global configuration of this AppEngine server.
  final Config _config;

  final FirestoreService _firestore;

  final DateTime Function() _now;

  /// Trigger github workflow to generate a content aware hash for the [gitRef].
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

  /// Locates the content aware hash for [workflow] or null.
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
    final List<Object?> data;
    try {
      data = json.decode(response.body) as List<Object?>;
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

  /// Finds the hash status for [job] and updates any tracking docs.
  Future<MergeQueueHashStatus> processWorkflowJob(
    WorkflowJobEvent job, {
    @visibleForTesting int maxAttempts = 5,
  }) async {
    final hash = await hashFromWorkflowJobEvent(job);
    if (hash == null) return MergeQueueHashStatus.ignoreJob;

    final headSha = job.workflowJob!.headSha!;

    final r = RetryOptions(
      maxAttempts: maxAttempts, // number of entries in the merge group?
    );

    try {
      final result = await r.retry(() async {
        // Important to do this bit in a transaction.
        final transaction = await _firestore.beginTransaction();

        try {
          return _updateFirestore(transaction, hash, headSha);
        } catch (e, s) {
          log.warn(
            'CAHS(headSha: $headSha, hash: $hash): failure to read/modify to firestore',
            e,
            s,
          );
          await _firestore.rollback(transaction);
          rethrow;
        }
      });
      return result;
    } catch (e, s) {
      log.warn(
        'CAHS(headSha: $headSha, hash: $hash): multiple failures calling _updateFirestore',
        e,
        s,
      );
      return MergeQueueHashStatus.error;
    }
  }

  Future<MergeQueueHashStatus> _updateFirestore(
    Transaction transaction,
    String hash,
    String headSha,
  ) async {
    // First, see if there's a document that already exits. This can be an old
    // content hash that already has artifacts, or one that is currently being
    // built.
    final doc = await ContentAwareHashBuilds.getByContentHash(
      _firestore,
      contentHash: hash,
    );

    // There isn't a doc - so we're the first request. Start one.
    if (doc == null) {
      await _firestore.commit(transaction, [
        Write(
          currentDocument: Precondition(exists: false),
          update: ContentAwareHashBuilds(
            buildStatus: BuildStatus.inProgress,
            createdOn: _now(),
            contentHash: hash,
            commitSha: headSha,
            waitingShas: [],
          ),
        ),
      ]);

      log.info(
        'CAHS(headSha: $headSha, hash: $hash): first hash seen; building',
      );
      return MergeQueueHashStatus.build;
    }

    // A doc exists; check to see if the artifacts are ready.
    if (doc.status == BuildStatus.success) {
      log.info(
        'CAHS(headSha: $headSha, hash: $hash): artifacts already built - would auto-complete merge group here',
      );
      return MergeQueueHashStatus.complete;
    }

    // A doc exists, but its not built yet - add ourselves to the waiting list
    // to be notified later.
    log.info(
      'CAHS(headSha: $headSha, hash: $hash): still building; adding to waiting list',
    );
    final commitResult = await _firestore.commit(transaction, [
      Write(
        update: doc,
        updateTransforms: [
          FieldTransform(
            fieldPath: ContentAwareHashBuilds.fieldWaitingShas,
            appendMissingElements: ArrayValue(values: [headSha.toValue()]),
          ),
        ],
      ),
    ]);

    log.debug(
      'CAHS(headSha: $headSha, hash: $hash): results: ${commitResult.writeResults?.map((e) => e.toJson())}',
    );
    return MergeQueueHashStatus.wait;
  }
}

enum MergeQueueHashStatus { wait, build, complete, ignoreJob, error }
