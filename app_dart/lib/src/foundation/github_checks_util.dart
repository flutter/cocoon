// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:github/github.dart' as github;

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

  Future<void> updateCheckRun(
    github.GitHub gitHubClient,
    github.RepositorySlug slug,
    github.CheckRun checkRun, {
    github.CheckRunStatus status,
    github.CheckRunConclusion conclusion,
    String detailsUrl,
    github.CheckRunOutput output,
  }) async {
    await gitHubClient.checks.checkRuns.updateCheckRun(
      slug,
      checkRun,
      status: status,
      conclusion: conclusion,
      detailsUrl: detailsUrl,
      output: output,
    );
  }

  Future<github.CheckRun> getCheckRun(
    github.GitHub gitHubClient,
    github.RepositorySlug slug,
    int id,
  ) async {
    return gitHubClient.checks.checkRuns.getCheckRun(
      slug,
      checkRunId: id,
    );
  }

  Future<github.CheckRun> createCheckRun(
    github.GitHub gitHubClient,
    github.RepositorySlug slug,
    String name,
    String headSha,
  ) async {
    return gitHubClient.checks.checkRuns.createCheckRun(
      slug,
      name: name,
      headSha: headSha,
    );
  }
}
