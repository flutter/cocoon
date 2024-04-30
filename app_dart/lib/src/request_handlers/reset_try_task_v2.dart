// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/service/scheduler_v2.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';

/// Runs all the applicable tasks for a given PR and commit hash. This will be
/// used to unblock rollers when creating a new commit is not possible.
@immutable
class ResetTryTaskV2 extends ApiRequestHandler<Body> {
  const ResetTryTaskV2({
    required super.config,
    required super.authenticationProvider,
    required this.scheduler,
  });

  final SchedulerV2 scheduler;

  static const String kOwnerParam = 'owner';
  static const String kRepoParam = 'repo';
  static const String kPullRequestNumberParam = 'pr';
  static const String kBuilderParam = 'builders';

  @override
  Future<Body> get() async {
    checkRequiredQueryParameters(<String>[kRepoParam, kPullRequestNumberParam]);
    final String owner = request!.uri.queryParameters[kOwnerParam] ?? 'flutter';
    final String repo = request!.uri.queryParameters[kRepoParam]!;
    final String pr = request!.uri.queryParameters[kPullRequestNumberParam]!;
    final String builders = request!.uri.queryParameters[kBuilderParam] ?? '';
    final List<String> builderList = getBuilderList(builders);

    final int? prNumber = int.tryParse(pr);
    if (prNumber == null) {
      throw const BadRequestException('$kPullRequestNumberParam must be a number');
    }
    final RepositorySlug slug = RepositorySlug(owner, repo);
    final GitHub github = await config.createGitHubClient(slug: slug);
    final PullRequest pullRequest = await github.pullRequests.get(slug, prNumber);
    await scheduler.triggerPresubmitTargets(pullRequest: pullRequest, builderTriggerList: builderList);
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
