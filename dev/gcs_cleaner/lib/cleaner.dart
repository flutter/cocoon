// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:gcloud/storage.dart';
import 'package:meta/meta.dart';

import 'git.dart';
import 'log.dart';

/// Cleans engine artifacts that are outside the retention policy.
class Cleaner {
  Cleaner({
    required this.fs,
    required this.engineGit,
    required this.frameworkGit,
    required this.gcs,
    required this.ttl,
    this.isDryrun = true,
    DateTime? now,
  }) : _now = now;

  final Storage gcs;

  final FileSystem fs;

  final Git engineGit;
  final Git frameworkGit;

  /// Whether calculated artifacts should be deleted.
  ///
  /// Default value is to run in dry run.
  final bool isDryrun;

  /// Injectable [DateTime] for testing.
  final DateTime? _now;

  /// Retention policy for how long artifacts can stay before they are deleted.
  final Duration ttl;

  /// Number of commits scanned.
  int totalCount = 0;

  /// Number of commits scanned that will not be deleted due to TTL.
  int totalNewCount = 0;

  int totalErrors = 0;

  Bucket get artifactBucket => gcs.bucket('flutter_infra_release');

  Future<void> clean() async {
    final Map<String, String> frameworkCommitTags = await frameworkGit.tags();
    final Map<String, String> engineCommitTags = <String, String>{};
    for (final frameworkCommit in frameworkCommitTags.keys) {
      final engineCommit = await frameworkGit.lookupEngineCommit(frameworkCommit);
      if (engineCommit != null) {
        // While unlikely, a single engine commit may be shipped in multiple releases.
        engineCommitTags[engineCommit] = frameworkCommitTags[frameworkCommit]!;
      }
    }

    final toBeDeleted = <String>{};

    final lsStream = artifactBucket.list(prefix: 'flutter/');
    log.info('Scanning gs://flutter_infra_release...');
    final items = await lsStream.toList();
    log.info('gs://flutter_infra_release has ${items.length} items');
    for (final item in items) {
      final commit = await processEngineArtifact(
        bucket: artifactBucket,
        item: item,
        engineCommitTags: engineCommitTags,
      );
      if (commit != null) {
        toBeDeleted.add(commit);
      }
    }

    log.info('$totalCount commits scanned from gs://flutter_infra_release');
    log.info('${engineCommitTags.keys.length} commits that are permanently retained');
    log.info('$totalErrors errors');
    log.info('$totalNewCount commits are younger than $ttl');
    log.info('${toBeDeleted.length} to be deleted');

    if (isDryrun) {
      final file = fs.currentDirectory.childFile('results_${_now?.toIso8601String()}.csv')..createSync();
      file.writeAsStringSync(toBeDeleted.join('\n'));
      log.info('Wrote ${file.absolute} with to be deleted files');
      log.info('Dryrun complete!');
      return;
    }

    final toDeleteFutures = <Future>[];
    for (final commit in toBeDeleted) {
      toDeleteFutures.add(deletePrefix('flutter/$commit'));
    }
    await Future.wait(toDeleteFutures);
  }

  /// If [BucketEntry] should be deleted, returns the associated commit hash.
  ///
  /// The given policy is enforced for retaining objects:
  /// 1. If an object cannot be translated to a commit
  /// 2. If object is a release engine version
  /// 3. If object's commit is newer than [ttl]
  @visibleForTesting
  Future<String?> processEngineArtifact({
    required Bucket bucket,
    required BucketEntry item,
    required Map<String, String> engineCommitTags,
  }) async {
    final parts = item.name.split('/');
    if (parts.length < 2) {
      return null;
    }
    final commit = parts[1];
    if (!item.isDirectory) {
      // There's stricter checks we could follow but skip for non commit folders
      return null;
    }

    totalCount++;
    if (totalCount % 1000 == 0) {
      log.info('Scanned $totalCount commits, still scanning...');
    }

    if (engineCommitTags.containsKey(commit)) {
      return null;
    }

    final commitTime = await engineGit.lookupCommitTime(commit);
    if (commitTime == null) {
      totalErrors++;
      return null;
    }
    final now = _now ?? DateTime.now();
    final Duration age = now.difference(commitTime);
    if (age < ttl) {
      totalNewCount++;
      if (totalNewCount % 500 == 0) {
        log.info('Scanned $totalNewCount new commits, still scanning...');
      }
      return null;
    }
    return commit;
  }

  /// Recursively go through the given prefix and delete all objects under it.
  Future<void> deletePrefix(String path) async {
    final page = await artifactBucket.page(prefix: path, pageSize: 1000);
    for (final item in page.items) {
      log.info('Deleting ${item.name}...');
      await artifactBucket.delete(item.name);
    }
  }
}
