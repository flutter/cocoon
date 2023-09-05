// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/git/git_cli.dart';
import 'package:github/github.dart';

class FakeGitCli extends GitCli {
  FakeGitCli(super.gitCloneMethod, super.cliCommand);

  bool _isGitRepo = false;
  bool _throwExp = false;

  late ProcessException _processException;
  late ProcessResult _processResult;

  set processException(ProcessException processException) => _processException = processException;
  set processResult(ProcessResult processResult) => _processResult = processResult;

  set isGitRepo(bool isGitRepo) => _isGitRepo = isGitRepo;
  set throwExp(bool throwExp) => _throwExp = throwExp;

  @override
  Future<bool> isGitRepository(String directory) async {
    if (_throwExp) {
      throw _processException;
    }
    return _isGitRepo;
  }

  @override
  Future<ProcessResult> cloneRepository({
    required RepositorySlug slug,
    required String workingDirectory,
    required String targetDirectory,
    List<String>? options,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> setupUserConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> setupUserEmailConfig({
    required RepositorySlug slug,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> setUpstream({
    required RepositorySlug slug,
    required String workingDirectory,
    required String branchName,
    required String token,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> fetchAll({
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> pullRebase({
    required String? workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> pullMerge({
    required String? workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> createBranch({
    required String newBranchName,
    required String workingDirectory,
    bool useCheckout = false,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> revertChange({
    required String commitSha,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> pushBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> deleteLocalBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> deleteRemoteBranch({
    required String branchName,
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> showOriginUrl({
    required String workingDirectory,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  @override
  Future<ProcessResult> switchBranch({
    required String workingDirectory,
    required String branchName,
    bool throwOnError = true,
  }) async {
    return _handleCall();
  }

  Future<ProcessResult> _handleCall() async {
    if (_throwExp) {
      throw _processException;
    }
    return _processResult;
  }
}
