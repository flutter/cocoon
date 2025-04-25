// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../foundation/utils.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/big_query.dart';

@immutable
/// Endpoint to collect the current GitHub API quota usage of the flutter-dashboard app.
///
/// This endpoint pushes data to BigQuery for metric collection to analyze usage over time. There
/// is a cron job set to run every minute, behind a [CacheRequestHandler] to ensure there exists
/// at most one entry per repo per minute.
///
/// BigQuery entries contain the following fields:
///   `timestamp`: [DateTime] of this entry.
///   `limit`: Total API calls allowed on flutter-dashboard.
///   `remaining`: Total number of API calls remaining before flutter-dashboard is blocked from sending further requests.
///   `resets`: [DateTime] when [remaining] will reset back to [limit].
class GithubRateLimitStatus extends RequestHandler<Body> {
  const GithubRateLimitStatus({
    required super.config,
    required BigQueryService bigQuery,
  }) : _bigQuery = bigQuery;

  final BigQueryService _bigQuery;

  @override
  Future<Body> get() async {
    final githubService = await config.createDefaultGitHubService();
    final quotaUsage = (await githubService.getRateLimit()).toJson();
    quotaUsage['timestamp'] = DateTime.now().toIso8601String();

    final remainingQuota = quotaUsage['remaining'] as int;
    final quotaLimit = quotaUsage['limit'] as int;
    const githubQuotaUsageSLO = 0.5;
    if (remainingQuota < githubQuotaUsageSLO * quotaLimit) {
      log.warn(
        'Remaining GitHub quota is $remainingQuota, which is less than quota '
        'usage SLO ${githubQuotaUsageSLO * quotaLimit} '
        '(${githubQuotaUsageSLO * 100}% of the limit $quotaLimit)).',
      );
    }

    /// Insert quota usage to BigQuery
    const githubQuotaTable = 'GithubQuotaUsage';
    await insertBigQuery(githubQuotaTable, quotaUsage, _bigQuery.tabledata);
    return Body.forJson(quotaUsage);
  }
}
