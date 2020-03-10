// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../request_handlers/refresh_github_commits.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';

/// Signature for a function that calculates the backoff duration to wait in
/// between requests when GitHub responds with an error.
///
/// The `attempt` argument is zero-based, so if the first attempt to request
/// from GitHub fails, and we're backing off before making the second attempt,
/// the `attempt` argument will be zero.
typedef GitHubBackoffCalculatorBranch = Duration Function(int attempt);

/// Default backoff calculator.
@visibleForTesting
Duration twoSecondLinearBackoffBranch(int attempt) {
  return const Duration(seconds: 2) * (attempt + 1);
}

/// Queries GitHub for the list of all available branches, and returns those
/// that match pre-defined branch regular expressions.
@immutable
class GetBranches extends RequestHandler<Body> {
  const GetBranches(
    Config config, {
    @visibleForTesting
        this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting
        this.gitHubBackoffCalculatorBranch = twoSecondLinearBackoffBranch,
  })  : assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculatorBranch != null),
        super(config: config);

  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculatorBranch gitHubBackoffCalculatorBranch;

  @override
  Future<Body> get() async {
    final GitHub github = await config.createGitHubClient();
    const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final Stream<Branch> branchList = github.repositories.listBranches(slug);
    final List<String> regExps = await loadBranchRegExps(
        branchHttpClientProvider, log, gitHubBackoffCalculatorBranch);
    final List<String> branches = <String>[];

    await for (Branch branch in branchList) {
      if (regExps
          .any((String regExp) => RegExp(regExp).hasMatch(branch.name))) {
        branches.add(branch.name);
      }
    }
    return Body.forJson(<String, dynamic>{'Branches': branches});
  }
}
