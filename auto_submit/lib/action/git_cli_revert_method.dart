// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/action/revert_method.dart';
import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/git/cli_command.dart';
import 'package:auto_submit/git/utilities.dart';
import 'package:auto_submit/git/git_cli.dart';
import 'package:auto_submit/git/git_repository_manager.dart';
import 'package:auto_submit/requests/exceptions.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/revert_issue_body_formatter.dart';
import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:retry/retry.dart';

class GitCliRevertMethod implements RevertMethod {
  @override
  Future<github.PullRequest?> createRevert(Config config, String initiatingAuthor, github.PullRequest pullRequest) async {
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

    // The exception is caught by the thrower.
    try {
      await gitRepositoryManager.cloneRepository();
      await gitRepositoryManager.setupConfig();
      await gitRepositoryManager.revertCommit(baseBranch, commitSha, slug, await config.generateGithubToken(slug));
    } finally {
      await gitRepositoryManager.deleteRepository();
    }

    final GitRevertBranchName gitRevertBranchName = GitRevertBranchName(commitSha);
    final GithubService githubService = await config.createGithubService(slug);

    const RetryOptions retryOptions =
        RetryOptions(delayFactor: Duration(seconds: 1), maxDelay: Duration(seconds: 1), maxAttempts: 4);

    Branch? branch;
    // Attempt a few times to get the branch name. This may not be needed.
    // Let the exception bubble up from here.
    await retryOptions.retry(
      () async {
        branch = await githubService.getBranch(slug, gitRevertBranchName.branch);
      },
      retryIf: (Exception e) => e is NotFoundException,
    );

    log.info('found branch ${slug.fullName}/${branch!.name}, safe to create revert request.');

    final RevertIssueBodyFormatter formatter = RevertIssueBodyFormatter(
      slug: slug,
      originalPrNumber: pullRequest.number!,
      initiatingAuthor: initiatingAuthor,
      originalPrTitle: pullRequest.title!,
      originalPrBody: pullRequest.body!,
    ).format;

    log.info('Attempting to create pull request with ${slug.fullName}/${gitRevertBranchName.branch}.');
    final github.PullRequest revertPullRequest = await githubService.createPullRequest(
      slug: slug,
      title: formatter.revertPrTitle,
      head: gitRevertBranchName.branch,
      base: baseBranch,
      draft: false,
      body: formatter.revertPrBody,
    );

    log.info('pull request number is: ${slug.fullName}/${revertPullRequest.number}');

    return revertPullRequest;
  }
}
