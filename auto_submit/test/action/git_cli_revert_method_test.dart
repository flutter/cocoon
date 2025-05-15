// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/action/git_cli_revert_method.dart';
import 'package:auto_submit/git/git_cli.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:github/src/common/model/pulls.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';

void main() {
  useTestLoggerPerTest();

  late _FakeGitCli gitCli;

  setUp(() {
    gitCli = _FakeGitCli();
  });

  test('createRevert uses the branch from the originating PR', () async {
    final config = _FakeConfig();
    final method = GitCliRevertMethod(gitCli: gitCli);
    final revert = await method.createRevert(
      config,
      'matanlurey',
      'I said so',
      generatePullRequest(
        baseRef: 'flutter-3.32-candidate.0',
        mergeCommitSha: 'abc123',
      ),
    );
    expect(gitCli.createBranch$newBranchName, 'revert_abc123');
    expect(gitCli.setUpstream$branchName, 'revert_abc123');
    expect(gitCli.pushBranch$branchName, 'revert_abc123');
    expect(revert?.base?.ref, 'flutter-3.32-candidate.0');
  });
}

final class _FakeConfig extends Fake implements Config {
  @override
  Future<String> generateGithubToken(RepositorySlug slug) async {
    return 'a_github_token';
  }

  @override
  Future<GithubService> createGithubService(RepositorySlug slug) async {
    return _FakeGithubService();
  }
}

final class _FakeGithubService extends Fake implements GithubService {
  @override
  Future<Branch> getBranch(RepositorySlug slug, String branchName) async {
    return Branch(branchName, null);
  }

  @override
  Future<List<PullRequestReview>> getPullRequestReviews(
    RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    return [];
  }

  @override
  Future<PullRequest> createPullRequest({
    required RepositorySlug slug,
    String? title,
    String? head,
    required String base,
    bool draft = false,
    String? body,
  }) async {
    return PullRequest(base: PullRequestHead(ref: base));
  }
}

final class _FakeGitCli extends Fake implements GitCli {
  @override
  Future<ProcessResult> cloneRepository({
    required RepositorySlug slug,
    required String workingDirectory,
    required String targetDirectory,
    List<String>? options,
    bool throwOnError = true,
  }) async {
    return ProcessResult(0, 0, '', '');
  }

  @override
  Future<ProcessResult> setupUserConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return ProcessResult(0, 0, '', '');
  }

  @override
  Future<ProcessResult> setupUserEmailConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return ProcessResult(0, 0, '', '');
  }

  late String createBranch$newBranchName;

  @override
  Future<ProcessResult> createBranch({
    required String newBranchName,
    required String workingDirectory,
    bool useCheckout = false,
    bool throwOnError = true,
  }) async {
    createBranch$newBranchName = newBranchName;
    return ProcessResult(0, 0, '', '');
  }

  late String setUpstream$branchName;

  @override
  Future<ProcessResult> setUpstream({
    required RepositorySlug slug,
    required String workingDirectory,
    required String branchName,
    required String token,
    bool throwOnError = true,
  }) async {
    setUpstream$branchName = branchName;
    return ProcessResult(0, 0, '', '');
  }

  @override
  Future<ProcessResult> revertChange({
    required String commitSha,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return ProcessResult(0, 0, '', '');
  }

  late String pushBranch$branchName;

  @override
  Future<ProcessResult> pushBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    pushBranch$branchName = branchName;
    return ProcessResult(0, 0, '', '');
  }
}
