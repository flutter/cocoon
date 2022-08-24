// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:auto_submit/model/big_query_revert_request_record.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart';

import 'access_client_provider.dart';

const String selectRevertRequestDml = r'''
SELECT organization, 
       repository, 
       reverting_pr_author, 
       reverting_pr_id, 
       reverting_pr_commit, 
       reverting_pr_url, 
       reverting_pr_created_timestamp, 
       reverting_pr_landed_timestamp,
       original_pr_author,
       original_pr_id,
       original_pr_commit,
       original_pr_url,
       original_pr_created_timestamp,
       original_pr_landed_timestamp
FROM `flutter-dashboard.revert.revert_requests`
WHERE reverting_pr_id=@REVERTING_PR_ID AND repository=@REPOSITORY
''';

const String insertRevertRequestDml = r'''
INSERT INTO `flutter-dashboard.revert.revert_requests` (
  organization, 
  repository, 
  reverting_pr_author, 
  reverting_pr_id, 
  reverting_pr_commit, 
  reverting_pr_url,
  reverting_pr_created_timestamp, 
  reverting_pr_landed_timestamp, 
  original_pr_author, 
  original_pr_id, 
  original_pr_commit, 
  original_pr_url, 
  original_pr_created_timestamp, 
  original_pr_landed_timestamp
) VALUES (
  @ORGANIZATION, 
  @REPOSITORY, 
  @REVERTING_PR_AUTHOR, 
  @REVERTING_PR_ID, 
  @REVERTING_PR_COMMIT, 
  @REVERTING_PR_URL, 
  @REVERTING_PR_CREATED_TIMESTAMP, 
  @REVERTING_PR_LANDED_TIMESTAMP, 
  @ORIGINAL_PR_AUTHOR, 
  @ORIGINAL_PR_ID, 
  @ORIGINAL_PR_COMMIT, 
  @ORIGINAL_PR_URL, 
  @ORIGINAL_PR_CREATED_TIMESTAMP, 
  @ORIGINAL_PR_LANDED_TIMESTAMP
) 
''';

const String deleteRevertRequestDml = r'''
DELETE FROM `flutter-dashboard.revert.revert_requests`
WHERE reverting_pr_id=@REVERTING_PR_ID AND repository=@REPOSITORY
''';

const String insertPullRequestDml = r'''
INSERT INTO `flutter-dashboard.autosubmit.pull_requests` (
  pr_created_timestamp,
  pr_landed_timestamp,
  organization,
  repository,
  author,
  pr_id,
  pr_commit,
  pr_request_type
) VALUES (
  @PR_CREATED_TIMESTAMP,
  @PR_LANDED_TIMESTAMP,
  @ORGANIZATION,
  @REPOSITORY,
  @AUTHOR,
  @PR_ID,
  @PR_COMMIT,
  @PR_REQUEST_TYPE
)
''';

const String selectPullRequestDml = r'''
SELECT pr_created_timestamp,
       pr_landed_timestamp,
       organization,
       repository,
       author,
       pr_id,
       pr_commit,
       pr_request_type
FROM `flutter-dashboard.autosubmit.pull_requests`
WHERE pr_id=@PR_ID AND repository=@REPOSITORY
''';

const String deletePullRequestDml = r'''
DELETE FROM `flutter-dashboard.autosubmit.pull_requests`
WHERE pr_id=@PR_ID AND repository=@REPOSITORY
''';

class BigqueryService {
  const BigqueryService(this.accessClientProvider);

  /// AccessClientProvider for OAuth 2.0 authenticated access client
  final AccessClientProvider accessClientProvider;

  /// Return a [TabledataResource] with an authenticated [client]
  Future<TabledataResource> defaultTabledata() async {
    final Client client = await accessClientProvider.createAccessClient(
      scopes: const <String>[BigqueryApi.bigqueryScope],
    );
    return BigqueryApi(client).tabledata;
  }

  /// Return a [JobsResource] with an authenticated [client]
  Future<JobsResource> defaultJobs() async {
    final Client client = await accessClientProvider.createAccessClient(
      scopes: const <String>[BigqueryApi.bigqueryScope],
    );
    return BigqueryApi(client).jobs;
  }

  /// Insert a new revert request into the database.
  Future<void> insertRevertRequest(String projectId, RevertRequestRecord revertRequestRecord) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: insertRevertRequestDml,
      queryParameters: <QueryParameter>[
        _createStringQueryParameter('ORGANIZATION', revertRequestRecord.organization),
        _createStringQueryParameter('REPOSITORY', revertRequestRecord.repository),
        _createStringQueryParameter('REVERTING_PR_AUTHOR', revertRequestRecord.revertingPrAuthor),
        _createIntegerQueryParameter('REVERTING_PR_ID', revertRequestRecord.revertingPrId!),
        _createStringQueryParameter('REVERTING_PR_COMMIT', revertRequestRecord.revertingPrCommit),
        _createStringQueryParameter('REVERTING_PR_URL', revertRequestRecord.revertingPrUrl),
        _createIntegerQueryParameter(
            'REVERTING_PR_CREATED_TIMESTAMP', revertRequestRecord.revertingPrCreatedTimestamp!),
        _createIntegerQueryParameter('REVERTING_PR_LANDED_TIMESTAMP', revertRequestRecord.revertingPrLandedTimestamp!),
        _createStringQueryParameter('ORIGINAL_PR_AUTHOR', revertRequestRecord.originalPrAuthor),
        _createIntegerQueryParameter('ORIGINAL_PR_ID', revertRequestRecord.originalPrId!),
        _createStringQueryParameter('ORIGINAL_PR_COMMIT', revertRequestRecord.originalPrCommit),
        _createStringQueryParameter('ORIGINAL_PR_URL', revertRequestRecord.originalPrUrl),
        _createIntegerQueryParameter('ORIGINAL_PR_CREATED_TIMESTAMP', revertRequestRecord.originalPrCreatedTimestamp!),
        _createIntegerQueryParameter('ORIGINAL_PR_LANDED_TIMESTAMP', revertRequestRecord.originalPrLandedTimestamp!),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw Exception('Insert revert request $revertRequestRecord did not complete.');
    }

    if (queryResponse.numDmlAffectedRows != null && int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw Exception('There was an error inserting $revertRequestRecord into the table.');
    }
  }

  /// Select a specific revert request from the database.
  Future<RevertRequestRecord> selectRevertRequestByRevertPrId(
      String projectId, int revertPrId, String repository) async {
    final JobsResource jobsResource = await defaultJobs();

    QueryRequest queryRequest = QueryRequest(
      query: selectRevertRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('REVERTING_PR_ID', revertPrId),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw Exception('Get revert request by id $revertPrId in repository $repository did not complete.');
    }

    List<TableRow>? tableRows = queryResponse.rows;
    if (tableRows == null || tableRows.isEmpty) {
      throw Exception('Could not find an entry for revert request id $revertPrId in repository $repository.');
    }

    if (tableRows.length != 1) {
      throw Exception('More than one record was returned for revert request id $revertPrId in repository $repository.');
    }

    RevertRequestRecord revertRequestRecord = RevertRequestRecord();
    TableRow tableRow = tableRows.first;

    revertRequestRecord
      ..organization = tableRow.f![0].v as String
      ..repository = tableRow.f![1].v as String
      ..revertingPrAuthor = tableRow.f![2].v as String
      ..revertingPrId = int.parse(tableRow.f![3].v as String)
      ..revertingPrCommit = tableRow.f![4].v as String
      ..revertingPrUrl = tableRow.f![5].v as String
      ..revertingPrCreatedTimestamp = int.parse(tableRow.f![6].v as String)
      ..revertingPrLandedTimestamp = int.parse(tableRow.f![7].v as String)
      ..originalPrAuthor = tableRow.f![8].v as String
      ..originalPrId = int.parse(tableRow.f![9].v as String)
      ..originalPrCommit = tableRow.f![10].v as String
      ..originalPrUrl = tableRow.f![11].v as String
      ..originalPrCreatedTimestamp = int.parse(tableRow.f![12].v as String)
      ..originalPrLandedTimestamp = int.parse(tableRow.f![13].v as String);

    return revertRequestRecord;
  }

  Future<void> deleteRevertRequestRecord(String projectId, int revertPrId, String repository) async {
    final JobsResource jobsResource = await defaultJobs();

    QueryRequest queryRequest = QueryRequest(
      query: deleteRevertRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('REVERTING_PR_ID', revertPrId),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw Exception('Delete revert request for $revertPrId in repository $repository did not complete.');
    }

    if (queryResponse.numDmlAffectedRows == null || int.parse(queryResponse.numDmlAffectedRows!) == 0) {
      throw Exception('The request record for $revertPrId in repository $repository was not deleted.');
    }

    if (int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw Exception('More than one row we deleted from the database for $revertPrId in repository $repository.');
    }
  }

  /// Insert a new pull request record into the database.
  Future<void> insertPullRequestRecord(String projectId, PullRequestRecord pullRequestRecord) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: insertPullRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('PR_CREATED_TIMESTAMP', pullRequestRecord.prCreatedTimestamp),
        _createIntegerQueryParameter('PR_LANDED_TIMESTAMP', pullRequestRecord.prLandedTimestamp),
        _createStringQueryParameter('ORGANIZATION', pullRequestRecord.organization),
        _createStringQueryParameter('REPOSITORY', pullRequestRecord.repository),
        _createStringQueryParameter('AUTHOR', pullRequestRecord.author),
        _createIntegerQueryParameter('PR_ID', pullRequestRecord.prId),
        _createStringQueryParameter('PR_COMMIT', pullRequestRecord.prCommit),
        _createStringQueryParameter('PR_REQUEST_TYPE', pullRequestRecord.prRequestType),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw Exception('Insert pull request record for $pullRequestRecord did not complete.');
    }

    if (queryResponse.numDmlAffectedRows != null && int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw Exception('There was an error inserting $pullRequestRecord into the table.');
    }
  }

  /// Select a specific pull request form the database.
  Future<PullRequestRecord> selectPullRequestRecordByPrId(String projectId, int prId, String repository) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: selectPullRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('PR_ID', prId),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw Exception('Get pull request by id for $prId and $repository did not complete.');
    }

    List<TableRow>? tableRows = queryResponse.rows;
    if (tableRows == null || tableRows.isEmpty) {
      throw Exception('Could not find an entry for pull request id $prId in repository $repository.');
    }

    if (tableRows.length != 1) {
      throw Exception('More than one record was returned for pull request id $prId in repository $repository.');
    }

    PullRequestRecord pullRequestRecord = PullRequestRecord();
    TableRow tableRow = tableRows.first;

    pullRequestRecord
      ..prCreatedTimestamp = int.parse(tableRow.f![0].v as String)
      ..prLandedTimestamp = int.parse(tableRow.f![1].v as String)
      ..organization = tableRow.f![2].v as String
      ..repository = tableRow.f![3].v as String
      ..author = tableRow.f![4].v as String
      ..prId = int.parse(tableRow.f![5].v as String)
      ..prCommit = tableRow.f![6].v as String
      ..prRequestType = tableRow.f![7].v as String;

    return pullRequestRecord;
  }

  Future<void> deletePullRequestRecord(String projectId, int pullRequestId, String repository) async {
    final JobsResource jobsResource = await defaultJobs();

    QueryRequest queryRequest = QueryRequest(
      query: deletePullRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('PR_ID', pullRequestId),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw Exception('Delete pull request for $pullRequestId in repository $repository did not complete.');
    }

    if (queryResponse.numDmlAffectedRows == null || int.parse(queryResponse.numDmlAffectedRows!) == 0) {
      throw Exception('The pull request record for $pullRequestId in repository $repository was not deleted.');
    }

    if (int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw Exception('More than one row we deleted from the database for $pullRequestId in repository $repository.');
    }
  }

  /// Create an int parameter for query substitution.
  QueryParameter _createIntegerQueryParameter(String name, int? value) {
    return QueryParameter(
        name: name,
        parameterType: QueryParameterType(type: 'INT64'),
        parameterValue: QueryParameterValue(value: value.toString()));
  }

  /// Create a String parameter for query substitution.
  QueryParameter _createStringQueryParameter(String name, String? value) {
    return QueryParameter(
        name: name,
        parameterType: QueryParameterType(type: 'STRING'),
        parameterValue: QueryParameterValue(value: value));
  }
}
