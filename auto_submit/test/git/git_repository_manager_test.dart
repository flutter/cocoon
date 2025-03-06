// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/git/cli_command.dart';
import 'package:auto_submit/git/git_cli.dart';
import 'package:auto_submit/git/git_repository_manager.dart';
import 'package:auto_submit/git/utilities.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  group('RepositoryManager', () {
    final workingDirectoryOutside = Directory.current.parent.parent.path;

    final workingDirectory = '${Directory.current.path}/test/repository';
    final targetRepoCheckoutDirectory =
        '${Directory.current.path}/test/repository/flutter_test';
    final cliCommand = CliCommand();
    final gitCli = GitCli(GitAccessMethod.SSH, cliCommand);
    final slug = RepositorySlug('ricardoamador', 'flutter_test');

    final gitRepositoryManager = GitRepositoryManager(
      slug: slug,
      workingDirectory: workingDirectory,
      cloneToDirectory: 'flutter_test',
      gitCli: gitCli,
    );

    setUp(() {
      final directory = Directory(workingDirectory);
      directory.createSync();
    });

    test('cloneRepository()', () async {
      await gitRepositoryManager.cloneRepository();
      expect(Directory(targetRepoCheckoutDirectory).existsSync(), isTrue);
    });

    test('cloneRepository() over existing dir.', () async {
      await cliCommand.runCliCommand(
        executable: 'mkdir',
        arguments: ['$workingDirectory/flutter_test'],
      );
      await gitRepositoryManager.cloneRepository();
      expect(
        Directory('$workingDirectoryOutside/flutter_test').existsSync(),
        isTrue,
      );
      expect(
        await gitCli.isGitRepository('$workingDirectoryOutside/flutter_test'),
        isTrue,
      );
    });

    test('deleteRepository()', () async {
      await gitRepositoryManager.cloneRepository();
      expect(Directory(targetRepoCheckoutDirectory).existsSync(), isTrue);
      await gitRepositoryManager.deleteRepository();
      expect(Directory(targetRepoCheckoutDirectory).existsSync(), isFalse);
    });

    tearDown(() async {
      await cliCommand.runCliCommand(
        executable: 'rm',
        arguments: ['-rf', targetRepoCheckoutDirectory],
      );
    });
  }, skip: true);
}
