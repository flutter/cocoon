// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/firestore/content_aware_hash_builds.dart';
import 'package:cocoon_service/src/model/github/workflow_job.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/content_aware_hash_service.dart';
import 'package:retry/retry.dart';

/// Fake for [Scheduler] to use for tests that rely on it.
class FakeContentAwareHashService implements ContentAwareHashService {
  final Config config;
  FakeContentAwareHashService({required this.config});

  final triggered = <String>[];

  ContentHashWorkflowStatus? nextReturn;

  @override
  Future<ContentHashWorkflowStatus> triggerWorkflow(String gitRef) async {
    triggered.add(gitRef);

    final status = nextReturn ?? ContentHashWorkflowStatus.ok;
    nextReturn = null;
    return status;
  }

  final hashFromWorkflowJobs = <WorkflowJobEvent>[];
  String? nextHashReturn;

  @override
  Future<String?> hashFromWorkflowJobEvent(WorkflowJobEvent workflow) {
    // make a copy
    hashFromWorkflowJobs.add(
      WorkflowJobEvent.fromJson(
        json.decode(json.encode(workflow.toJson())) as Map<String, Object?>,
      ),
    );
    final hash = nextHashReturn;
    nextHashReturn = null;
    return Future.value(hash);
  }

  final processWorkflowJobs = <WorkflowJobEvent>[];
  ContentAwareHashStatus? nextStatusReturn;

  @override
  Future<ContentAwareHashStatus> processWorkflowJob(
    WorkflowJobEvent workflow, {
    RetryOptions? retry,
  }) {
    processWorkflowJobs.add(workflow);
    final status =
        nextStatusReturn ??
        (status: MergeQueueHashStatus.ignoreJob, contentHash: '');
    nextStatusReturn = null;
    return Future.value(status);
  }

  final List<({String commitSha, bool successful})> completedShas = [];
  List<String>? nextCompletedShas;

  @override
  Future<List<String>> completeArtifacts({
    required String commitSha,
    required bool successful,
    int maxAttempts = 5,
  }) async {
    completedShas.add((commitSha: commitSha, successful: successful));
    final shas = nextCompletedShas ?? const [];
    nextCompletedShas = null;
    return shas;
  }

  final hashByCommit = <String, String>{};
  @override
  Future<String?> getHashByCommitSha(String commitSha) async {
    return hashByCommit[commitSha];
  }

  final buildsByHash = <String, ContentAwareHashBuilds>{};

  @override
  Future<List<ContentAwareHashBuilds>> getBuildsByHash(String hash) async {
    return [?buildsByHash[hash]];
  }
}
