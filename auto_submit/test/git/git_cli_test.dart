// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/git/cli_command.dart';
import 'package:auto_submit/git/utilities.dart';
import 'package:auto_submit/git/git_cli.dart';
import 'package:github/github.dart';

import 'package:test/test.dart';

void main() {
  group('Testing git commands', () {
    late CliCommand cliCommand;
    late GitCli gitCli;
    final String workingDirectory = '${Directory.current.path}/test/repository';
    final String fullRepoCheckoutPath = '$workingDirectory/test_repo';
    final RepositorySlug slug = RepositorySlug('flutter', 'test_repo');

    late ProcessResult initProcessResult;

    setUp(() async {
      cliCommand = CliCommand();
      final Directory directory = Directory(workingDirectory);
      directory.createSync();
      gitCli = GitCli(GitAccessMethod.SSH, cliCommand);
      initProcessResult = await cliCommand.runCliCommand(
        executable: 'git',
        arguments: [
          'init',
          slug.name,
          '-b',
          'main',
        ],
        workingDirectory: workingDirectory,
        throwOnError: false,
      );
    });

    void validateInit() {
      expect(initProcessResult, isNotNull);
      expect(initProcessResult.exitCode, isZero);
      expect(Directory(fullRepoCheckoutPath).existsSync(), isTrue);
    }

    test('isGitRepository()', () async {
      validateInit();
      expect(await gitCli.isGitRepository(fullRepoCheckoutPath), isTrue);
    });

    test('createBranch()', () async {
      validateInit();

      final ProcessResult branchProcessResult = await gitCli.createBranch(
        newBranchName: 'test_branch',
        workingDirectory: fullRepoCheckoutPath,
        useCheckout: true,
      );
      expect(branchProcessResult, isNotNull);
      expect(branchProcessResult.exitCode, isZero);

      final ProcessResult processResult = await cliCommand.runCliCommand(
        executable: 'git',
        arguments: ['status'],
        workingDirectory: fullRepoCheckoutPath,
      );
      expect((processResult.stdout as String).contains('On branch test_branch'), isTrue);
    });

    tearDown(() async {
      await cliCommand.runCliCommand(
        executable: 'rm',
        arguments: ['-rf', fullRepoCheckoutPath],
      );
    });
  });
}
