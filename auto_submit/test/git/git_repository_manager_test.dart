import 'dart:io';

import 'package:auto_submit/git/cli_command.dart';
import 'package:auto_submit/git/git_access_method.dart';
import 'package:auto_submit/git/git_cli.dart';
import 'package:auto_submit/git/git_repository_manager.dart';
import 'package:github/github.dart';

import 'package:test/test.dart';

void main() {
  group(
    'RepositoryManager',
    () {
      final String workingDirectoryOutside = Directory.current.parent.parent.path;

      final String workingDirectory = '${Directory.current.path}/test/repository';
      final String targetRepoCheckoutDirectory = '${Directory.current.path}/test/repository/flutter_test';
      final CliCommand cliCommand = CliCommand();
      final GitCli gitCli = GitCli(GitAccessMethod.SSH, cliCommand);
      final RepositorySlug slug = RepositorySlug('ricardoamador', 'flutter_test');

      final GitRepositoryManager gitRepositoryManager = GitRepositoryManager(
        slug: slug,
        workingDirectory: workingDirectory,
        cloneToDirectory: 'flutter_test',
        gitCli: gitCli,
      );

      setUp(() {
        final Directory directory = Directory(workingDirectory);
        directory.createSync();
      });

      test('cloneRepository()', () async {
        await gitRepositoryManager.cloneRepository();
        expect(Directory(targetRepoCheckoutDirectory).existsSync(), isTrue);
      });

      test('cloneRepository() over existing dir.', () async {
        await cliCommand.runCliCommand(executable: 'mkdir', arguments: ['$workingDirectory/flutter_test']);
        await gitRepositoryManager.cloneRepository();
        expect(Directory('$workingDirectoryOutside/flutter_test').existsSync(), isTrue);
        expect(await gitCli.isGitRepository('$workingDirectoryOutside/flutter_test'), isTrue);
      });

      test('deleteRepository()', () async {
        await gitRepositoryManager.cloneRepository();
        expect(Directory(targetRepoCheckoutDirectory).existsSync(), isTrue);
        await gitRepositoryManager.deleteRepository();
        expect(Directory(targetRepoCheckoutDirectory).existsSync(), isFalse);
      });

      // This will not run any longer without conflicts.
      // test('Create revert request and push to github.',() async {
      //   const String commitSha = '26a2304c62de558920657bd1839008e19991e1d8';
      //   const GitRevertBranchName gitRevertBranchName = GitRevertBranchName(commitSha);
      //   await gitCloneManager.cloneRepository();
      //   await gitCloneManager.revertCommit('main', commitSha);
      //   await gitCloneManager.deleteRepository();
      // });

      // test('revertCommit()', () async {});

      tearDown(() async {
        await cliCommand.runCliCommand(executable: 'rm', arguments: ['-rf', targetRepoCheckoutDirectory]);
      });
    },
    skip: true,
  );
}
