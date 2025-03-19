// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';
import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';
import 'package:retry/retry.dart';

import '../service/config.dart';

/// Wrapper class for github checkrun service. This is used to simplify
/// mocking during testing because some of the subclasses are private.
class GithubChecksUtil {
  const GithubChecksUtil();
  Future<Map<String, github.CheckRun>> allCheckRuns(
    github.GitHub gitHubClient,
    CheckSuiteEvent checkSuiteEvent,
  ) async {
    final allCheckRuns =
        await gitHubClient.checks.checkRuns
            .listCheckRunsInSuite(
              checkSuiteEvent.repository!.slug(),
              checkSuiteId: checkSuiteEvent.checkSuite!.id!,
            )
            .toList();
    return {
      for (github.CheckRun check in allCheckRuns) check.name as String: check,
    };
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

  /// Finds all check suites that are associated with a given git [ref].
  Future<List<github.CheckSuite>> listCheckSuitesForRef(
    github.GitHub gitHubClient,
    github.RepositorySlug slug, {
    required String ref,
    int? appId,
    String? checkName,
  }) async {
    const r = RetryOptions(maxAttempts: 3, delayFactor: Duration(seconds: 2));
    return r.retry(
      () async {
        return gitHubClient.checks.checkSuites
            .listCheckSuitesForRef(
              slug,
              ref: ref,
              appId: appId,
              checkName: checkName,
            )
            .toList();
      },
      retryIf: (Exception e) => e is github.GitHubError || e is SocketException,
    );
  }

  /// Sends a request to github checks api to update a [CheckRun] with a given
  /// [status] and [conclusion].
  Future<void> updateCheckRun(
    Config config,
    github.RepositorySlug slug,
    github.CheckRun checkRun, {
    github.CheckRunStatus status = github.CheckRunStatus.queued,
    github.CheckRunConclusion? conclusion,
    String? detailsUrl,
    github.CheckRunOutput? output,
  }) async {
    const r = RetryOptions(maxAttempts: 3, delayFactor: Duration(seconds: 2));
    return r.retry(
      () async {
        final gitHubClient = await config.createGitHubClient(slug: slug);
        await gitHubClient.checks.checkRuns.updateCheckRun(
          slug,
          checkRun,
          status: status,
          conclusion: conclusion,
          detailsUrl: detailsUrl,
          output: output,
        );
      },
      retryIf: (Exception e) => e is github.GitHubError || e is SocketException,
    );
  }

  Future<github.CheckRun> getCheckRun(
    Config config,
    github.RepositorySlug slug,
    int? id,
  ) async {
    const r = RetryOptions(maxAttempts: 3, delayFactor: Duration(seconds: 2));
    return r.retry(
      () async {
        final gitHubClient = await config.createGitHubClient(slug: slug);
        return gitHubClient.checks.checkRuns.getCheckRun(slug, checkRunId: id!);
      },
      retryIf: (Exception e) => e is github.GitHubError || e is SocketException,
    );
  }

  /// Sends a request to GitHub's Checks API to create a new [github.CheckRun].
  ///
  /// The newly created checkrun will be associated in [slug] to [sha] as [name].
  ///
  /// Optionally, will have [output] to give information to users, or
  /// initialized with [conclusion].
  Future<github.CheckRun> createCheckRun(
    Config config,
    github.RepositorySlug slug,
    String sha,
    String name, {
    github.CheckRunOutput? output,
    github.CheckRunConclusion? conclusion,
  }) async {
    const r = RetryOptions(maxAttempts: 3, delayFactor: Duration(seconds: 2));
    return r.retry(
      () async {
        return _createCheckRun(
          config,
          slug,
          sha,
          name,
          output: output,
          conclusion: conclusion,
        );
      },
      retryIf: (_) => true,
      onRetry: (e) {
        log.warn(
          'createCheckRun fails for slug: ${slug.fullName}, sha: $sha, name: $name.',
          e,
        );
      },
    );
  }

  Future<github.CheckRun> _createCheckRun(
    Config config,
    github.RepositorySlug slug,
    String sha,
    String name, {
    github.CheckRunOutput? output,
    github.CheckRunConclusion? conclusion,
  }) async {
    final gitHubClient = await config.createGitHubClient(slug: slug);
    return gitHubClient.checks.checkRuns.createCheckRun(
      slug,
      name: name,
      headSha: sha,
      output: output,
      conclusion: conclusion,
    );
  }
}
