// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/utils.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/github_service.dart';

/// Endpoint to collect the current GitHub API quota usage of Cocoon on all supported Flutter repos.
///
/// This endpoint pushes data to BigQuery for metric collection to analyze usage over time.
@immutable
class GithubRateLimitStatus extends RequestHandler<Body> {
  const GithubRateLimitStatus(
    Config config,
  ) : super(config: config);

  @override
  Future<Body> get() async {
    final List<Map<String, dynamic>> totalQuotaUsage = <Map<String, dynamic>>[];

    /// Pull quota usage for all supported repos.
    for (String repository in Config.supportedRepos) {
      final GithubService githubService = await config.createGithubService('flutter', repository);
      final Map<String, dynamic> quotaUsage = (await githubService.getRateLimit()).toJson();
      quotaUsage['repo'] = repository;
      totalQuotaUsage.add(quotaUsage);

      /// Insert quota usage for [repository] to BigQuery
      const String githubQuotaTable = 'GithubQuotaUsage';
      await insertBigquery(githubQuotaTable, quotaUsage, await config.createTabledataResourceApi(), log);
    }

    return Body.forJson(totalQuotaUsage);
  }
}
