// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/access_client_provider.dart';
import 'package:googleapis/bigquery/v2.dart';

/// The sql query to query the build statistic from the
/// `flutter-dashboard.datasite.luci_prod_build_status`.
///
/// The schema of the `luci_prod_build_status` table:
/// time	            TIMESTAMP
/// date	            DATE
/// sha	              STRING
/// flaky_builds	    STRING
/// succeeded_builds	STRING
/// branch	          STRING
/// device_os       	STRING
/// pool	            STRING
/// repo	            STRING
/// builder_name	    STRING
/// success_count	    INTEGER
/// failure_count	    INTEGER
/// is_flaky	        INTEGER
///
/// This returns latest [LIMIT] number of build stats for each builder.
const String getBuilderStatisticQuery = r'''
select builder_name,
       sum(is_flaky) as flaky_number,
       count(*) as total_number,
       string_agg(case when is_flaky = 1 then flaky_builds end, ', ') as flaky_builds,
       string_agg(succeeded_builds, ', ') as succeeded_builds,
       array_agg(case when is_flaky = 1 then sha end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as recent_flaky_commit,
       array_agg(case when is_flaky = 1 then flaky_builds end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as flaky_build_of_recent_flaky_commit,
       sum(is_flaky)/count(*) as flaky_ratio,
       min(date) as from_date,
       max(date) as to_date
from (select *, row_number() over (partition by builder_name order by time desc) as rank from `flutter-dashboard.datasite.luci_prod_build_status`)
where date>=date_sub(current_date(), interval 30 day) and
      builder_name not like '%Drone' and
      repo='flutter' and
      branch='master' and
      pool = 'luci.flutter.prod' and
      builder_name not like '%Beta%' and
      builder_name not like '% beta %' and
      builder_name not like '%Stable%' and
      builder_name not like '% stable %' and
      builder_name not like '%Dev%' and
      builder_name not like '% dev %' and
      rank<=@LIMIT
group by builder_name;
''';

const String getStagingBuilderStatisticQuery = r'''
select builder_name,
       sum(is_flaky) as flaky_number,
       count(*) as total_number,
       string_agg(case when is_flaky = 1 then flaky_builds end, ', ') as flaky_builds,
       string_agg(succeeded_builds, ', ') as succeeded_builds,
       array_agg(case when is_flaky = 1 then sha end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as recent_flaky_commit,
       array_agg(case when is_flaky = 1 then flaky_builds end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as flaky_build_of_recent_flaky_commit,
       sum(is_flaky)/count(*) as flaky_ratio,
       min(date) as from_date,
       max(date) as to_date
from (select *, row_number() over (partition by builder_name order by time desc) as rank from `flutter-dashboard.datasite.luci_staging_build_status`)
where date>=date_sub(current_date(), interval 30 day) and
      builder_name not like '%Drone' and
      repo='flutter' and
      branch='master' and
      pool = 'luci.flutter.staging' and
      builder_name not like '%Beta%' and
      builder_name not like '% beta %' and
      rank<=@LIMIT
group by builder_name;
''';

// Returns builds in the past 30 days to exclude obsolete historical data.
const String getRecordsQuery = r'''
select sha, is_flaky, failure_count from `flutter-dashboard.datasite.luci_staging_build_status`
where builder_name=@BUILDER_NAME and date>=date_sub(current_date(), interval 30 day)
order by time desc
limit @LIMIT
''';

class BigqueryService {
  const BigqueryService(this.accessClientProvider);

  /// AccessClientProvider for OAuth 2.0 authenticated access client
  final AccessClientProvider accessClientProvider;

  /// Return a [TabledataResource] with an authenticated [client]
  Future<TabledataResource> defaultTabledata() async {
    final client = await accessClientProvider.createAccessClient(
      scopes: const <String>[BigqueryApi.bigqueryScope],
    );
    return BigqueryApi(client).tabledata;
  }

  /// Return a [JobsResource] with an authenticated [client]
  Future<JobsResource> defaultJobs() async {
    final client = await accessClientProvider.createAccessClient(
      scopes: const <String>[BigqueryApi.bigqueryScope],
    );
    return BigqueryApi(client).jobs;
  }

  /// Return the top [limit] number of current builder statistic.
  ///
  /// See getBuilderStatisticQuery to get the detail information about the table
  /// schema
  Future<List<BuilderStatistic>> listBuilderStatistic(
    String projectId, {
    int limit = 100,
    String bucket = 'prod',
  }) async {
    final jobsResource = await defaultJobs();
    final query = QueryRequest.fromJson(<String, Object>{
      'query':
          bucket == 'staging'
              ? getStagingBuilderStatisticQuery
              : getBuilderStatisticQuery,
      'queryParameters': <Map<String, Object>>[
        <String, Object>{
          'name': 'LIMIT',
          'parameterType': <String, Object>{'type': 'INT64'},
          'parameterValue': <String, Object>{'value': '$limit'},
        },
      ],
      'useLegacySql': false,
    });
    final response = await jobsResource.query(query, projectId);
    if (!response.jobComplete!) {
      throw 'job does not complete';
    }
    final result = <BuilderStatistic>[];
    for (final row in response.rows!) {
      final builder = row.f![0].v as String;
      var flakyBuilds = (row.f![3].v as String?)?.split(', ');
      flakyBuilds?.sort();
      flakyBuilds = flakyBuilds?.reversed.toList();
      var succeededBuilds = (row.f![4].v as String?)?.split(', ');
      succeededBuilds?.sort();
      succeededBuilds = succeededBuilds?.reversed.toList();
      result.add(
        BuilderStatistic(
          name: builder,
          flakyRate: double.parse(row.f![7].v as String),
          flakyBuilds: flakyBuilds ?? const <String>[],
          succeededBuilds: succeededBuilds ?? const <String>[],
          recentCommit: row.f![5].v as String?,
          flakyBuildOfRecentCommit: row.f![6].v as String?,
          flakyNumber: int.parse(row.f![1].v as String),
          totalNumber: int.parse(row.f![2].v as String),
          fromDate: row.f![8].v as String?,
          toDate: row.f![9].v as String?,
        ),
      );
    }
    return result;
  }

  /// Return the list of current builder statistic.
  ///
  /// See getBuilderStatisticQuery to get the detail information about the table
  /// schema
  Future<List<BuilderRecord>> listRecentBuildRecordsForBuilder(
    String projectId, {
    String? builder,
    int? limit,
  }) async {
    final jobsResource = await defaultJobs();
    final query = QueryRequest.fromJson(<String, Object>{
      'query': getRecordsQuery,
      'parameterMode': 'NAMED',
      'queryParameters': <Map<String, Object>>[
        <String, Object>{
          'name': 'BUILDER_NAME',
          'parameterType': <String, Object>{'type': 'STRING'},
          'parameterValue': <String, Object?>{'value': builder},
        },
        <String, Object>{
          'name': 'LIMIT',
          'parameterType': <String, Object>{'type': 'INT64'},
          'parameterValue': <String, Object>{'value': '$limit'},
        },
      ],
      'useLegacySql': false,
    });
    final response = await jobsResource.query(query, projectId);
    if (!response.jobComplete!) {
      throw 'job does not complete';
    }
    final result = <BuilderRecord>[];
    // When a test is newly marked as flaky, it is possible no execution exists.
    if (response.rows == null) {
      return result;
    }
    for (final row in response.rows!) {
      result.add(
        BuilderRecord(
          commit: row.f![0].v as String,
          isFlaky: row.f![1].v as String != '0',
          isFailed: row.f![2].v as String != '0',
        ),
      );
    }
    return result;
  }
}

class BuilderRecord {
  BuilderRecord({
    required this.commit,
    required this.isFlaky,
    required this.isFailed,
  });

  final String commit;
  final bool isFlaky;
  final bool isFailed;
}

class BuilderStatistic {
  BuilderStatistic({
    required this.name,
    required this.flakyRate,
    required this.flakyNumber,
    required this.totalNumber,
    this.flakyBuilds,
    this.succeededBuilds,
    this.recentCommit,
    this.flakyBuildOfRecentCommit,
    this.fromDate,
    this.toDate,
  });

  final String name;
  final double flakyRate;
  final List<String>? flakyBuilds;
  final List<String>? succeededBuilds;
  final String? recentCommit;
  final String? flakyBuildOfRecentCommit;
  final int flakyNumber;
  final int totalNumber;
  final String? fromDate;
  final String? toDate;
}
