// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'git_cli.dart';
import 'utilities.dart';

class GitRepositoryManager {
  final RepositorySlug slug;
  final String workingDirectory;
  String? cloneToDirectory;
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
  ///
  /// Throw out rather than decomposing the return codes from the ProcessResult.
  Future<void> cloneRepository() async {
    if (Directory(targetCloneDirectory).existsSync()) {
      // Blow the directory away instead of trying to update it.
      Directory(targetCloneDirectory).deleteSync(recursive: true);
    }

    // Checking out a sparse copy will not checkout source files but will still
    // allow a revert since we only care about the commitSha.
    // Source: https://git-scm.com/docs/git-clone
    await gitCli.cloneRepository(
      slug: slug,
      workingDirectory: workingDirectory,
      targetDirectory: targetCloneDirectory,
      options: ['--sparse'],
    );
  }

  Future<void> setupConfig() async {
    await gitCli.setupUserConfig(slug: slug, workingDirectory: targetCloneDirectory);
    await gitCli.setupUserEmailConfig(slug: slug, workingDirectory: targetCloneDirectory);
  }

  /// Revert a commit in the current repository.
  ///
  /// The [baseBranchName] is the branch we want to branch from. In this case it
  /// will almost always be the default branch name. The target branch is
  /// preformatted with the commitSha.
  Future<void> revertCommit(String baseBranchName, String commitSha, RepositorySlug slug, String token) async {
    final GitRevertBranchName revertBranchName = GitRevertBranchName(commitSha);
    // Working directory for these must be repo checkout directory.
    // Check out the baseBranchName before doing anything.
    await gitCli.createBranch(
      newBranchName: revertBranchName.branch,
      workingDirectory: targetCloneDirectory,
      useCheckout: true,
    );

    await gitCli.setUpstream(
      slug: slug,
      workingDirectory: targetCloneDirectory,
      branchName: revertBranchName.branch,
      token: token,
    );

    await gitCli.revertChange(
      commitSha: commitSha,
      workingDirectory: targetCloneDirectory,
    );

    await gitCli.pushBranch(
      branchName: revertBranchName.branch,
      workingDirectory: targetCloneDirectory,
    );
  }

  /// Delete the repository managed by this instance.
  Future<void> deleteRepository() async {
    log.info('Deleting clone directory $targetCloneDirectory');
    if (Directory(targetCloneDirectory).existsSync()) {
      Directory(targetCloneDirectory).deleteSync(recursive: true);
    }
  }
}
