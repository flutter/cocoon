// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import 'flaky_handler_utils.dart';

@immutable
class UpdateExistingFlakyIssue extends ApiRequestHandler<Body> {
  const UpdateExistingFlakyIssue(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  static const String kThresholdKey = 'threshold';
  static const int kFreshPeriodForOpenFlake = 7; // days

  @override
  Future<Body> get() async {
    final RepositorySlug slug = config.flutterSlug;
    final GithubService gitHub = config.createGithubServiceWithToken(await config.githubOAuthToken);
    final BigqueryService bigquery = await config.createBigQueryService();
    final List<BuilderStatistic> builderStatisticList = await bigquery.listBuilderStatistic(kBigQueryProjectId);
    final Map<String, Issue> nameToExistingIssue = await getExistingIssues(gitHub, slug, state: 'open');
    for (final BuilderStatistic statistic in builderStatisticList) {
      if (nameToExistingIssue.containsKey(statistic.name)) {
        await _addCommentToExistingIssue(gitHub, slug,
            statistic: statistic, existingIssue: nameToExistingIssue[statistic.name]);
      }
    }
    return Body.forJson(const <String, dynamic>{
      'Status': 'success',
    });
  }

  double get _threshold => double.parse(request.uri.queryParameters[kThresholdKey]);

  Future<void> _addCommentToExistingIssue(
    GithubService gitHub,
    RepositorySlug slug, {
    @required BuilderStatistic statistic,
    @required Issue existingIssue,
  }) async {
    if (DateTime.now().difference(existingIssue.createdAt) < const Duration(days: kFreshPeriodForOpenFlake)) {
      return;
    }
    final IssueUpdateBuilder updateBuilder =
        IssueUpdateBuilder(statistic: statistic, threshold: _threshold, existingIssue: existingIssue);
    await gitHub.createComment(slug, issueNumber: existingIssue.number, body: updateBuilder.issueUpdateComment);
    await gitHub.replaceLabelsForIssue(slug, issueNumber: existingIssue.number, labels: updateBuilder.issueLabels);
  }
}
