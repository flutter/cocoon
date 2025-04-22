// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';

import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/firestore/commit.dart' as fs;
import '../model/firestore/task.dart' as fs;
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/firestore.dart';
import '../service/firestore/commit_and_tasks.dart';
import '../service/luci_build_service.dart';
import '../service/luci_build_service/build_tags.dart';
import '../service/luci_build_service/commit_task_ref.dart';
import '../service/scheduler/ci_yaml_fetcher.dart';

/// Reruns a postsubmit LUCI build.
@immutable
final class RerunProdTask extends ApiRequestHandler<Body> {
  const RerunProdTask({
    required super.config,
    required super.authenticationProvider,
    required LuciBuildService luciBuildService,
    required CiYamlFetcher ciYamlFetcher,
    required FirestoreService firestore,
  }) : _ciYamlFetcher = ciYamlFetcher,
       _luciBuildService = luciBuildService,
       _firestore = firestore;

  final LuciBuildService _luciBuildService;
  final CiYamlFetcher _ciYamlFetcher;
  final FirestoreService _firestore;

  static const _paramBranch = 'branch';
  static const _paramRepo = 'repo';
  static const _paramCommitSha = 'commit';
  static const _paramTaskName = 'task';
  static const _paramInclude = 'include';

  @override
  Future<Body> post() async {
    checkRequiredParameters([
      _paramBranch,
      _paramRepo,
      _paramCommitSha,
      _paramTaskName,
    ]);

    final {
      _paramBranch: String branch,
      _paramRepo: String repo,
      _paramCommitSha: String commitSha,
      _paramTaskName: String taskName,
    } = requestData!;

    final email = authContext?.email ?? 'EMAIL-MISSING';
    final slug = RepositorySlug('flutter', repo);

    // Ensure the commit exists in Firestore.
    final commit = await fs.Commit.tryFromFirestoreBySha(
      _firestore,
      sha: commitSha,
    );
    if (commit == null) {
      throw NotFoundException('No commit "$commitSha" found');
    }

    if (taskName == 'all') {
      final statusesToRerun = {
        ...fs.Task.taskFailStatusSet,
        ...?(requestData![_paramInclude] as String?)?.split(','),
      };
      if (statusesToRerun.difference(fs.Task.legalStatusValues)
          case final invalid when invalid.isNotEmpty) {
        throw BadRequestException(
          'Invalid "include" statuses: ${invalid.join(',')}.',
        );
      }
      final ranTasks = await _markAllTestsForRerun(
        commit: commit,
        slug: slug,
        branch: branch,
        email: email,
        statusesToRerun: statusesToRerun,
      );
      return Body.forJson(ranTasks);
    }

    if (requestData!.containsKey(_paramInclude)) {
      throw const BadRequestException(
        'Cannot provide "$_paramInclude" when a task name is specified.',
      );
    }

    // Ensure the task exists in Firestore.
    final task = await _firestore.queryLatestTask(
      commitSha: commitSha,
      builderName: taskName,
    );
    if (task == null) {
      throw NotFoundException(
        'No task "$taskName" found for commit "$commitSha"',
      );
    }

    final didRerun = await _rerunSpecificTask(
      commit: commit,
      task: task,
      slug: slug,
      branch: branch,
      email: email,
    );
    if (!didRerun) {
      throw InternalServerError('Failed to rerun task "$taskName"');
    }

    return Body.empty;
  }

  @useResult
  Future<Map<String, Target>> _getPostsubmitTargets(fs.Commit commit) async {
    final ciYaml = await _ciYamlFetcher.getCiYamlByFirestoreCommit(commit);
    final targets = [
      ...ciYaml.postsubmitTargets(),
      if (ciYaml.isFusion)
        ...ciYaml.postsubmitTargets(type: CiType.fusionEngine),
    ];
    return {for (final t in targets) t.name: t};
  }

  @useResult
  Target? _findMatchingTarget(
    fs.Task task, {
    required Map<String, Target> postsubmitTargets,
  }) {
    final matched = postsubmitTargets[task.taskName];
    if (matched == null) {
      // Could happen (https://github.com/flutter/flutter/issues/165522).
      log.warn(
        'No matching target ("${task.taskName}") found in '
        '${[...postsubmitTargets.keys]}.',
      );
      return null;
    }
    return matched;
  }

  @useResult
  Future<List<String>> _markAllTestsForRerun({
    required fs.Commit commit,
    required RepositorySlug slug,
    required String branch,
    required String email,
    required Set<String> statusesToRerun,
  }) async {
    // Find the latest task for each task for this commit.
    final transaction = await _firestore.beginTransaction();

    final latestTasks =
        CommitAndTasks(
          commit,
          await _firestore.queryAllTasksForCommit(
            commitSha: commit.sha,
            transaction: transaction,
          ),
        ).withMostRecentTaskOnly().tasks;

    final wasMarkedNew = <String>[];
    final documentWrites = <g.Write>[];

    // Wait for cancellations?
    final Future<void> cancelRunningTasks;
    if (statusesToRerun.contains(fs.Task.statusInProgress)) {
      cancelRunningTasks = _luciBuildService.cancelBuildsBySha(
        sha: commit.sha,
        reason: '$email cancelled build to schedule a fresh rerun',
      );
    } else {
      cancelRunningTasks = Future.value();
    }

    // If the task should be ignored, ignore it.
    for (final task in latestTasks) {
      if (!statusesToRerun.contains(task.status)) {
        continue;
      }

      // If it appears the task was in progress, cancel any running builders
      // and crease a _new_ task (to represent a new run).
      if (task.status == fs.Task.statusInProgress) {
        // Mark cancelled.
        documentWrites.add(
          fs.Task.patchStatus(
            fs.TaskId(
              commitSha: task.commitSha,
              currentAttempt: task.currentAttempt,
              taskName: task.taskName,
            ),
            fs.Task.statusCancelled,
          ),
        );
      }

      // Start a new task.
      task.resetAsRetry();
      documentWrites.add(
        g.Write(currentDocument: g.Precondition(exists: false), update: task),
      );
    }

    await Future.wait([
      cancelRunningTasks,
      _firestore.commit(transaction, documentWrites),
    ]);

    return wasMarkedNew;
  }

  Future<bool> _rerunSpecificTask({
    required fs.Commit commit,
    required fs.Task task,
    required RepositorySlug slug,
    required String branch,
    required String email,
  }) async {
    final allTargets = await _getPostsubmitTargets(commit);
    final taskTarget = _findMatchingTarget(task, postsubmitTargets: allTargets);
    if (taskTarget == null) {
      return false;
    }

    return await _luciBuildService.checkRerunBuilder(
      commit: CommitRef.fromFirestore(commit),
      target: taskTarget,
      tags: [TriggerdByBuildTag(email: email)],
      task: task,
    );
  }
}
