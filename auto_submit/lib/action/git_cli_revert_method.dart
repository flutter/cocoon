import 'dart:io';

import 'package:auto_submit/action/revert_method.dart';
import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/git/cli_command.dart';
import 'package:auto_submit/git/git_access_method.dart';
import 'package:auto_submit/git/git_cli.dart';
import 'package:auto_submit/git/git_repository_manager.dart';
import 'package:auto_submit/git/git_revert_branch_name.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart' as github;

// TODO update this as this is the old probably non working code.
class GitCliRevertMethod implements RevertMethod {
  GitCliRevertMethod();

  // // This method is directly from the revert facilitator.
  // Future<void> processRevertRequest(
  //   github.RepositorySlug slug,
  //   String workingDirectory,
  //   GitAccessMethod gitAccessMethod,
  //   String commitSha,
  // ) async {
  //   final GitRepositoryManager repositoryManager = GitRepositoryManager(
  //     slug: slug,
  //     //path/to/working/directory/
  //     workingDirectory: workingDirectory,
  //     //flutter_453a23
  //     cloneToDirectory: '${slug.name}_$commitSha',
  //     gitCli: GitCli(gitAccessMethod, CliCommand()),
  //   );

  //   // final String cloneToFullPath = '$workingDirectory/${slug.name}_$commitSha';
  //   try {
  //     await repositoryManager.cloneRepository();
  //     await repositoryManager.revertCommit('main', commitSha);
  //   } finally {
  //     await repositoryManager.deleteRepository();
  //   }
  // }

  @override
  Future<Object> createRevert(Config config, github.PullRequest pullRequest) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final String commitSha = pullRequest.mergeCommitSha!;
    // we will need to collect the pr number after the revert request is generated.

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);
    final String baseBranch = repositoryConfiguration.defaultBranch;

    final String cloneToDirectory = '${slug.name}_$commitSha';
    final GitRepositoryManager gitRepositoryManager = GitRepositoryManager(
      slug: slug,
      workingDirectory: Directory.current.path,
      cloneToDirectory: cloneToDirectory,
      gitCli: GitCli(GitAccessMethod.HTTP, CliCommand()),
    );

    try {
      final bool cloned = await gitRepositoryManager.cloneRepository();
      if (!cloned) {
        log.warning('Unable to clone ${slug.fullName}');
        throw 'Unable to clone repository.';
      }
      await gitRepositoryManager.revertCommit(baseBranch, commitSha);
    } finally {
      await gitRepositoryManager.deleteRepository();
    }

    // at this point the branch has been created an pushed to the remote.
    final GitRevertBranchName gitRevertBranchName = GitRevertBranchName(commitSha);
    final GithubService githubService = await config.createGithubService(slug);
    final github.PullRequest revertPullRequest = await githubService.createPullRequest(
      slug: slug,
      head: gitRevertBranchName.branch,
      base: baseBranch,
    );
    return revertPullRequest;
  }
}
