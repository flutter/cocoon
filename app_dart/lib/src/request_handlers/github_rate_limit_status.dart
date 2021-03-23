// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../foundation/utils.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/github_service.dart';

/// Endpoint to collect the current GitHub API quota usage of the flutter-dashboard app.
///
/// This endpoint pushes data to BigQuery for metric collection to analyze usage over time. There
/// is a cron job set to run every minute, behind a [CacheRequestHandler] to ensure there exists
/// at most one entry per repo per minute.
///
/// BigQuery entries contain the following fields:
///   `repo`: Repository corresponding to this entry.
///   `timestamp`: Timestamp of this entry.
///   `limit`: Total API calls allowed against `repo`.
///   `remaining`: Total number of API calls remaining before `repo` is blocked from sending further requests.
///   `reset`: Timestamp when the API rate limiting will next reset `remaining` back to `limit`.
@immutable
class GithubRateLimitStatus extends RequestHandler<Body> {
  const GithubRateLimitStatus(Config config) : super(config: config);

  @override
  Future<Body> get() async {
    final GithubService githubService = await config.createGithubService('flutter', 'flutter');
    final Map<String, dynamic> quotaUsage = (await githubService.getRateLimit()).toJson();
    quotaUsage['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    quotaUsage['repo'] = 'flutter';

    /// Insert quota usage to BigQuery
    const String githubQuotaTable = 'GithubQuotaUsage';
    await insertBigquery(githubQuotaTable, quotaUsage, await config.createTabledataResourceApi(), log);

    return Body.forJson(quotaUsage);
  }
}
