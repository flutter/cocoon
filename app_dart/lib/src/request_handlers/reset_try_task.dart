// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';

/// Runs all the applicable tasks for a given PR and commit hash. This will be
/// used to unblock rollers when creating a new commit is not possible.
@immutable
class ResetTryTask extends ApiRequestHandler<Body> {
  const ResetTryTask(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.scheduler,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  final Scheduler scheduler;

  static const String kOwnerParam = 'owner';
  static const String kRepoParam = 'repo';
  static const String kPullRequestNumberParam = 'pr';

  @override
  Future<Body> get() async {
    checkRequiredQueryParameters(<String>[kRepoParam, kPullRequestNumberParam]);
    final String owner = request!.uri.queryParameters[kOwnerParam] ?? 'flutter';
    final String repo = request!.uri.queryParameters[kRepoParam]!;
    final String pr = request!.uri.queryParameters[kPullRequestNumberParam]!;

    final int? prNumber = int.tryParse(pr);
    if (prNumber == null) {
      throw const BadRequestException('$kPullRequestNumberParam must be a number');
    }
    final RepositorySlug slug = RepositorySlug(owner, repo);
    final GitHub github = await config.createGitHubClient(slug: slug);
    final PullRequest pullRequest = await github.pullRequests.get(slug, prNumber);
    await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
    return Body.empty;
  }
}
