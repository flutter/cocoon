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
  const ResetTryTask({
    required super.config,
    required super.authenticationProvider,
    required this.scheduler,
  });

  final Scheduler scheduler;

  static const String kOwnerParam = 'owner';
  static const String kRepoParam = 'repo';
  static const String kPullRequestNumberParam = 'pr';
  static const String kBuilderParam = 'builders';

  @override
  Future<Body> get(Request request) async {
    checkRequiredQueryParameters(request, <String>[
      kRepoParam,
      kPullRequestNumberParam,
    ]);
    final owner = request.uri.queryParameters[kOwnerParam] ?? 'flutter';
    final repo = request.uri.queryParameters[kRepoParam]!;
    final pr = request.uri.queryParameters[kPullRequestNumberParam]!;
    final builders = request.uri.queryParameters[kBuilderParam] ?? '';
    final builderList = getBuilderList(builders);

    final prNumber = int.tryParse(pr);
    if (prNumber == null) {
      throw const BadRequestException(
        '$kPullRequestNumberParam must be a number',
      );
    }
    final slug = RepositorySlug(owner, repo);
    final github = await config.createGitHubClient(slug: slug);
    final pullRequest = await github.pullRequests.get(slug, prNumber);
    await scheduler.triggerPresubmitTargets(
      pullRequest: pullRequest,
      builderTriggerList: builderList,
    );
    return Body.empty;
  }

  /// Parses [builders] to a String list.
  ///
  /// The [builders] parameter is expecting comma joined string, e.g. 'builder1, builder2'.
  /// Returns an empty list if no [builders] is specified.
  List<String> getBuilderList(String builders) {
    if (builders.isEmpty) {
      return <String>[];
    }
    return builders.split(',').map((String builder) => builder.trim()).toList();
  }
}
