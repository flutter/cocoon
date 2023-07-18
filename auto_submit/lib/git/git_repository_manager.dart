// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'git_cli.dart';
import 'git_revert_branch_name.dart';

class GitRepositoryManager {
  final String workingDirectory;
  String? cloneToDirectory;
  final RepositorySlug slug;
  final GitCli gitCli;

  late String targetCloneDirectory;

  /// RepositoryManager will perform clone, revert and delete on the repository
  /// in the working directory that is cloned to [cloneToDirectory].
  ///
  /// If the clonedToDirectory is not provided then the name of the repository
  /// will be used as the cloneToDirectory.
  GitRepositoryManager({
    required this.slug,
    //path/to/working/directory
    required this.workingDirectory,
    //reponame_commitSha
    this.cloneToDirectory,
    required this.gitCli,
  }) {
    cloneToDirectory ??= slug.name;
    targetCloneDirectory = '$workingDirectory/$cloneToDirectory';
  }

  /// Clone the repository identified by the slug.
  Future<bool> cloneRepository() async {
    if (Directory(targetCloneDirectory).existsSync()) {
      // Could possibly add a check for the slug in the remote url.
      if (!await gitCli.isGitRepository(targetCloneDirectory)) {
        Directory(targetCloneDirectory).deleteSync(recursive: true);
      } else {
        return true;
      }
    }

    // Checking out a sparse copy will not checkout source files but will still
    // allow a revert since we only care about the commitSha.
    final ProcessResult processResult = await gitCli.cloneRepository(
      slug: slug,
      workingDirectory: workingDirectory,
      targetDirectory: targetCloneDirectory,
      options: ['--sparse'],
    );

    if (processResult.exitCode != 0) {
      log.severe('An error has occurred cloning repository ${slug.fullName} to dir $targetCloneDirectory');
      log.severe('${slug.fullName}, $targetCloneDirectory: stdout: ${processResult.stdout}');
      log.severe('${slug.fullName}, $targetCloneDirectory: stderr: ${processResult.stderr}');
      return false;
    } else {
      log.info('${slug.fullName} was cloned successfully to directory $targetCloneDirectory');
      return true;
    }
  }

  /// Revert a commit in the current repository.
  ///
  /// The [baseBranchName] is the branch we want to branch from. In this case it
  /// will almost always be the default branch name. The target branch is
  /// preformatted with the commitSha.
  Future<void> revertCommit(String baseBranchName, String commitSha) async {
    final GitRevertBranchName revertBranchName = GitRevertBranchName(commitSha);
    // Working directory for these must be repo checkout directory.
    log.info('Running fetch ');
    // await gitCli.fetchAll(targetCloneDirectory);
    // await gitCli.pullRebase(targetCloneDirectory);
    await gitCli.createBranch(
      newBranchName: revertBranchName.branch,
      workingDirectory: targetCloneDirectory,
      useCheckout: true,
    );
    await gitCli.revertChange(
      commitSha: commitSha,
      workingDirectory: targetCloneDirectory,
    );
    await gitCli.pushBranch(revertBranchName.branch, targetCloneDirectory);
  }

  /// Delete the repository managed by this instance.
  Future<void> deleteRepository() async {
    if (Directory(targetCloneDirectory).existsSync()) {
      Directory(targetCloneDirectory).deleteSync(recursive: true);
    }
  }
}
