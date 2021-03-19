// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';
import 'dart:io';

import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

import '../datastore/cocoon_config.dart';

/// Wrapper class for github checkrun service. This is used to simplify
/// mocking during testing because some of the subclasses are private.
class GithubChecksUtil {
  const GithubChecksUtil();
  Future<Map<String, github.CheckRun>> allCheckRuns(
    github.GitHub gitHubClient,
    CheckSuiteEvent checkSuiteEvent,
  ) async {
    final List<github.CheckRun> allCheckRuns = await gitHubClient.checks.checkRuns
        .listCheckRunsInSuite(
          checkSuiteEvent.repository.slug(),
          checkSuiteId: checkSuiteEvent.checkSuite.id,
        )
        .toList();
    return Map<String, github.CheckRun>.fromIterable(
      allCheckRuns,
      key: (dynamic check) => check.name as String,
      value: (dynamic check) => check as github.CheckRun,
    );
  }

  Future<github.CheckSuite> getCheckSuite(
    github.GitHub gitHubClient,
    github.RepositorySlug slug,
    int checkSuiteId,
  ) async {
    return gitHubClient.checks.checkSuites.getCheckSuite(
      slug,
      checkSuiteId: checkSuiteId,
    );
  }

  /// Sends a request to github checks api to update a [CheckRun] with a given
  /// [status] and [conclusion].
  Future<void> updateCheckRun(
    Config cocoonConfig,
    github.RepositorySlug slug,
    github.CheckRun checkRun, {
    github.CheckRunStatus status,
    github.CheckRunConclusion conclusion,
    String detailsUrl,
    github.CheckRunOutput output,
  }) async {
    const RetryOptions r = RetryOptions(
      maxAttempts: 3,
      delayFactor: Duration(seconds: 2),
    );
    return r.retry(() async {
      final github.GitHub gitHubClient = await cocoonConfig.createGitHubClient(
        slug.owner,
        slug.name,
      );
      await gitHubClient.checks.checkRuns.updateCheckRun(
        slug,
        checkRun,
        status: status,
        conclusion: conclusion,
        detailsUrl: detailsUrl,
        output: output,
      );
    }, retryIf: (Exception e) => e is github.GitHubError || e is SocketException);
  }

  Future<github.CheckRun> getCheckRun(
    Config cocoonConfig,
    github.RepositorySlug slug,
    int id,
  ) async {
    const RetryOptions r = RetryOptions(
      maxAttempts: 3,
      delayFactor: Duration(seconds: 2),
    );
    return r.retry(() async {
      final github.GitHub gitHubClient = await cocoonConfig.createGitHubClient(
        slug.owner,
        slug.name,
      );
      return await gitHubClient.checks.checkRuns.getCheckRun(
        slug,
        checkRunId: id,
      );
    }, retryIf: (Exception e) => e is github.GitHubError || e is SocketException);
  }

  /// Sends a request to github checks api to create a new [CheckRun] associated
  /// with a task [name] and commit [headSha].
  Future<github.CheckRun> createCheckRun(
    Config cocoonConfig,
    github.RepositorySlug slug,
    String name,
    String headSha,
  ) async {
    const RetryOptions r = RetryOptions(
      maxAttempts: 3,
      delayFactor: Duration(seconds: 2),
    );
    return r.retry(() async {
      return _createCheckRun(
        cocoonConfig,
        slug,
        name,
        headSha,
      );
    }, retryIf: (Exception e) => e is github.GitHubError);
  }

  Future<github.CheckRun> _createCheckRun(
    Config cocoonConfig,
    github.RepositorySlug slug,
    String name,
    String headSha,
  ) async {
    final github.GitHub gitHubClient = await cocoonConfig.createGitHubClient(
      slug.owner,
      slug.name,
    );
    return gitHubClient.checks.checkRuns.createCheckRun(
      slug,
      name: name,
      headSha: headSha,
    );
  }
}
