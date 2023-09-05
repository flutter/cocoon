// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:github/github.dart';
import 'package:logging/logging.dart';

import 'cli_command.dart';

import 'git_access_method.dart';

/// Class to wrap the command line calls to git.
class GitCli {
  Logger logger = Logger('RepositoryManager');

  static const String GIT = 'git';

  final String repositoryHttpPrefix = 'https://github.com/';
  final String repositorySshPrefix = 'git@github.com:';

  late String repositoryPrefix;

  late CliCommand _cliCommand;

  GitCli(GitAccessMethod gitCloneMethod, CliCommand cliCommand) {
    switch (gitCloneMethod) {
      case GitAccessMethod.SSH:
        repositoryPrefix = repositorySshPrefix;
        break;
      case GitAccessMethod.HTTP:
        repositoryPrefix = repositoryHttpPrefix;
        break;
    }
    _cliCommand = cliCommand;
  }

  /// Check to see if the current directory is a git repository.
  Future<bool> isGitRepository(String directory) async {
    final ProcessResult processResult = await _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'rev-parse',
      ],
      throwOnError: false,
      workingDirectory: directory,
    );

    return processResult.exitCode == 0;
  }

  /// Checkout repository if it does not currently exist on disk.
  /// We will need to protect against multiple checkouts just in case multiple
  /// calls occur at the same time.
  Future<ProcessResult> cloneRepository({
    required RepositorySlug slug,
    required String workingDirectory,
    required String targetDirectory,
    List<String>? options,
    bool throwOnError = true,
  }) async {
    final List<String> clone = <String>[
      'clone',
      '$repositoryPrefix${slug.fullName}',
      targetDirectory,
    ];
    if (options != null) {
      clone.addAll(options);
    }
    final ProcessResult processResult = await _cliCommand.runCliCommand(
      executable: GIT,
      arguments: clone,
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );

    return processResult;
  }

  Future<ProcessResult> setupUserConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'config',
        '--global',
        'user.name',
        // '"autosubmit[bot]"',
        '"ricardoamador"',
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  Future<ProcessResult> setupUserEmailConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'config',
        '--global',
        'user.email',
        // TODO not sure if the bot will end up needing a valid email.
        '"ricardoamador@google.com"',
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  /// This is necessary with forked repos but may not be necessary with the bot
  /// as the bot has direct access to the repository.
  Future<ProcessResult> setUpstream({
    required RepositorySlug slug,
    required String workingDirectory,
    required String branchName,
    required String token,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'remote',
        'set-url',
        'origin',
        'https://autosubmit[bot]:$token@github.com/${slug.fullName}.git',
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  /// Fetch all new refs for the repository.
  Future<ProcessResult> fetchAll({
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'fetch',
        '--all',
      ],
      throwOnError: throwOnError,
    );
  }

  Future<ProcessResult> pullRebase({
    required String? workingDirectory,
    bool throwOnError = true,
  }) async {
    return _updateRepository(
      workingDirectory: workingDirectory,
      pullMethod: '--rebase',
      throwOnError: throwOnError,
    );
  }

  Future<ProcessResult> pullMerge({
    required String? workingDirectory,
    bool throwOnError = true,
  }) async {
    return _updateRepository(
      workingDirectory: workingDirectory,
      pullMethod: '--merge',
      throwOnError: throwOnError,
    );
  }

  /// Run the git pull rebase command to keep the repository up to date.
  Future<ProcessResult> _updateRepository({
    required String? workingDirectory,
    required String pullMethod,
    bool throwOnError = true,
  }) async {
    final ProcessResult processResult = await _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'pull',
        pullMethod,
      ],
      workingDirectory: workingDirectory,
    );
    return processResult;
  }

  /// Checkout and create a branch for the current edit.
  ///
  /// TODO The strategy may be unneccessary here as the bot will not have to
  /// create its own fork of the repo.
  Future<ProcessResult> createBranch({
    required String newBranchName,
    required String workingDirectory,
    bool useCheckout = false,
    bool throwOnError = true,
  }) async {
    // Then create the new branch.
    List<String> args;
    if (useCheckout) {
      args = <String>[
        'checkout',
        '-b',
        newBranchName,
      ];
    } else {
      args = <String>[
        'branch',
        newBranchName,
      ];
    }

    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: args,
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  /// Revert a pull request commit.
  Future<ProcessResult> revertChange({
    required String commitSha,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    // Issue a revert of the pull request.
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'revert',
        '--no-edit',
        '-m',
        '1',
        commitSha,
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  /// Push changes made to the local branch to github.
  Future<ProcessResult> pushBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'push',
        '--verbose',
        'origin',
        branchName,
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  /// Delete a local branch from the repo.
  Future<ProcessResult> deleteLocalBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'branch',
        '-D',
        branchName,
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  /// Delete a remote branch from the repo.
  ///
  /// When merging a pull request the pr branch is not automatically deleted.
  Future<ProcessResult> deleteRemoteBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'push',
        'origin',
        '--delete',
        branchName,
      ],
      throwOnError: throwOnError,
    );
  }

  /// Get the remote origin of the current repository.
  Future<ProcessResult> showOriginUrl({
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'config',
        '--get',
        'remote.origin.url',
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }

  Future<ProcessResult> switchBranch({
    required String workingDirectory,
    required String branchName,
    bool throwOnError = true,
  }) async {
    return _cliCommand.runCliCommand(
      executable: GIT,
      arguments: <String>[
        'switch',
        branchName,
      ],
      workingDirectory: workingDirectory,
      throwOnError: throwOnError,
    );
  }
}
