import 'dart:io';

import 'package:auto_submit/git/git_cli.dart';
import 'package:github/github.dart';

class FakeGitCli extends GitCli {
  FakeGitCli(super.gitCloneMethod, super.cliCommand);

  bool isGitRepositoryMock = true;
  ProcessResult defaultProcessResult = ProcessResult(0, 0, stdout, stderr);

  @override
  Future<bool> isGitRepository(String directory) async {
    return isGitRepositoryMock;
  }

  late ProcessResult processResultCloneRepositoryMock = defaultProcessResult;

  @override
  Future<ProcessResult> cloneRepository({
    required RepositorySlug slug,
    required String workingDirectory,
    required String targetDirectory,
    List<String>? options,
    bool throwOnError = true,
  }) async {
    return processResultCloneRepositoryMock;
  }

  late ProcessResult processResultSetupUserConfig = defaultProcessResult;

  @override
  Future<ProcessResult> setupUserConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultSetupUserConfig;
  }

  late ProcessResult processResultSetupUserEmailConfig = defaultProcessResult;

  @override
  Future<ProcessResult> setupUserEmailConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultSetupUserEmailConfig;
  }

  late ProcessResult processResultSetUpstream = defaultProcessResult;

  @override
  Future<ProcessResult> setUpstream({
    required RepositorySlug slug,
    required String workingDirectory,
    required String branchName,
    required String token,
    bool throwOnError = true,
  }) async {
    return processResultSetUpstream;
  }

  late ProcessResult processResultFetchAll = defaultProcessResult;

  @override
  Future<ProcessResult> fetchAll({
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultFetchAll;
  }

  late ProcessResult processResultPullRebase = defaultProcessResult;

  @override
  Future<ProcessResult> pullRebase({
    required String? workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultPullRebase;
  }

  late ProcessResult processResultPullMerge = defaultProcessResult;

  @override
  Future<ProcessResult> pullMerge({
    required String? workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultPullMerge;
  }

  late ProcessResult processResultCreateBranch = defaultProcessResult;

  @override
  Future<ProcessResult> createBranch({
    required String newBranchName,
    required String workingDirectory,
    bool useCheckout = false,
    bool throwOnError = true,
  }) async {
    return processResultCreateBranch;
  }

  late ProcessResult processResultRevertChange = defaultProcessResult;

  @override
  Future<ProcessResult> revertChange({
    required String commitSha,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultRevertChange;
  }

  late ProcessResult processResultPushBranch = defaultProcessResult;

  @override
  Future<ProcessResult> pushBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultPushBranch;
  }

  late ProcessResult processResultDeleteLocalBranch = defaultProcessResult;

  @override
  Future<ProcessResult> deleteLocalBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultDeleteLocalBranch;
  }

  late ProcessResult processResultDeleteRemoteBranch = defaultProcessResult;

  @override
  Future<ProcessResult> deleteRemoteBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultDeleteRemoteBranch;
  }

  late ProcessResult processResultShowOriginUrl = defaultProcessResult;

  @override
  Future<ProcessResult> showOriginUrl({
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return processResultShowOriginUrl;
  }

  late ProcessResult processResultSwitchBranch = defaultProcessResult;

  @override
  Future<ProcessResult> switchBranch({
    required String workingDirectory,
    required String branchName,
    bool throwOnError = true,
  }) async {
    return processResultSwitchBranch;
  }
}
