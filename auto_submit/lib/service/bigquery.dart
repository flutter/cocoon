// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:auto_submit/model/big_query_revert_request_record.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart';

import 'access_client_provider.dart';

const String selectRevertRequestDml = r'''
SELECT organization,
       repository,
       reverting_pr_author,
       reverting_pr_number,
       reverting_pr_commit,
       reverting_pr_created_timestamp,
       reverting_pr_landed_timestamp,
       original_pr_author,
       original_pr_number,
       original_pr_commit,
       original_pr_created_timestamp,
       original_pr_landed_timestamp,
       review_issue_assignee,
       review_issue_number,
       review_issue_created_timestamp,
       review_issue_landed_timestamp,
       review_issue_closed_by
FROM `flutter-dashboard.revert.revert_requests`
WHERE reverting_pr_number=@REVERTING_PR_NUMBER AND repository=@REPOSITORY
''';

/// Query to select all of the open revert review issues for update. Note that
/// the review_issue_landed_timestamp is 0 for open issues. 0 is the default
/// value instead of null since it is safer to process.
const String selectRevertRequestReviewIssuesDml = r'''
SELECT review_issue_assignee,
       review_issue_number,
       review_issue_created_timestamp,
       review_issue_landed_timestamp,
       review_issue_closed_by
FROM `flutter-dashboard.revert.revert_requests`
WHERE review_issue_landed_timestamp=0
''';

const String updateRevertRequestRecordReviewDml = '''
UPDATE `flutter-dashboard.revert.revert_requests`
SET review_issue_landed_timestamp=@REVIEW_ISSUE_LANDED_TIMESTAMP,
    review_issue_closed_by=@REVIEW_ISSUE_CLOSED_BY
WHERE review_issue_number=@REVIEW_ISSUE_NUMBER
''';

const String insertRevertRequestDml = r'''
INSERT INTO `flutter-dashboard.revert.revert_requests` (
  organization,
  repository,
  reverting_pr_author,
  reverting_pr_number,
  reverting_pr_commit,
  reverting_pr_created_timestamp,
  reverting_pr_landed_timestamp,
  original_pr_author,
  original_pr_number,
  original_pr_commit,
  original_pr_created_timestamp,
  original_pr_landed_timestamp,
  review_issue_assignee,
  review_issue_number,
  review_issue_created_timestamp,
  review_issue_landed_timestamp,
  review_issue_closed_by
) VALUES (
  @ORGANIZATION,
  @REPOSITORY,
  @REVERTING_PR_AUTHOR,
  @REVERTING_PR_NUMBER,
  @REVERTING_PR_COMMIT,
  @REVERTING_PR_CREATED_TIMESTAMP,
  @REVERTING_PR_LANDED_TIMESTAMP,
  @ORIGINAL_PR_AUTHOR,
  @ORIGINAL_PR_NUMBER,
  @ORIGINAL_PR_COMMIT,
  @ORIGINAL_PR_CREATED_TIMESTAMP,
  @ORIGINAL_PR_LANDED_TIMESTAMP,
  @REVIEW_ISSUE_ASSIGNEE,
  @REVIEW_ISSUE_NUMBER,
  @REVIEW_ISSUE_CREATED_TIMESTAMP,
  @REVIEW_ISSUE_LANDED_TIMESTAMP,
  @REVIEW_ISSUE_CLOSED_BY
)
''';

const String deleteRevertRequestDml = r'''
DELETE FROM `flutter-dashboard.revert.revert_requests`
WHERE reverting_pr_number=@REVERTING_PR_NUMBER AND repository=@REPOSITORY
''';

const String insertPullRequestDml = r'''
INSERT INTO `flutter-dashboard.autosubmit.pull_requests` (
  pr_created_timestamp,
  pr_landed_timestamp,
  organization,
  repository,
  author,
  pr_number,
  pr_commit,
  pr_request_type
) VALUES (
  @PR_CREATED_TIMESTAMP,
  @PR_LANDED_TIMESTAMP,
  @ORGANIZATION,
  @REPOSITORY,
  @AUTHOR,
  @PR_NUMBER,
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
       pr_number,
       pr_commit,
       pr_request_type
FROM `flutter-dashboard.autosubmit.pull_requests`
WHERE pr_number=@PR_NUMBER AND repository=@REPOSITORY
''';

const String deletePullRequestDml = r'''
DELETE FROM `flutter-dashboard.autosubmit.pull_requests`
WHERE pr_number=@PR_NUMBER AND repository=@REPOSITORY
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
  Future<void> insertRevertRequestRecord({
    required String projectId,
    required RevertRequestRecord revertRequestRecord,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: insertRevertRequestDml,
      queryParameters: <QueryParameter>[
        _createStringQueryParameter(
          'ORGANIZATION',
          revertRequestRecord.organization,
        ),
        _createStringQueryParameter(
          'REPOSITORY',
          revertRequestRecord.repository,
        ),
        _createStringQueryParameter(
          'REVERTING_PR_AUTHOR',
          revertRequestRecord.author,
        ),
        _createIntegerQueryParameter(
          'REVERTING_PR_NUMBER',
          revertRequestRecord.prNumber!,
        ),
        _createStringQueryParameter(
          'REVERTING_PR_COMMIT',
          revertRequestRecord.prCommit,
        ),
        _createIntegerQueryParameter(
          'REVERTING_PR_CREATED_TIMESTAMP',
          revertRequestRecord.prCreatedTimestamp!.millisecondsSinceEpoch,
        ),
        _createIntegerQueryParameter(
          'REVERTING_PR_LANDED_TIMESTAMP',
          revertRequestRecord.prLandedTimestamp!.millisecondsSinceEpoch,
        ),
        _createStringQueryParameter(
          'ORIGINAL_PR_AUTHOR',
          revertRequestRecord.originalPrAuthor,
        ),
        _createIntegerQueryParameter(
          'ORIGINAL_PR_NUMBER',
          revertRequestRecord.originalPrNumber!,
        ),
        _createStringQueryParameter(
          'ORIGINAL_PR_COMMIT',
          revertRequestRecord.originalPrCommit,
        ),
        _createIntegerQueryParameter(
          'ORIGINAL_PR_CREATED_TIMESTAMP',
          revertRequestRecord.originalPrCreatedTimestamp!.millisecondsSinceEpoch,
        ),
        _createIntegerQueryParameter(
          'ORIGINAL_PR_LANDED_TIMESTAMP',
          revertRequestRecord.originalPrLandedTimestamp!.millisecondsSinceEpoch,
        ),
        _createStringQueryParameter(
          'REVIEW_ISSUE_ASSIGNEE',
          revertRequestRecord.reviewIssueAssignee,
        ),
        _createIntegerQueryParameter(
          'REVIEW_ISSUE_NUMBER',
          revertRequestRecord.reviewIssueNumber,
        ),
        _createIntegerQueryParameter(
          'REVIEW_ISSUE_CREATED_TIMESTAMP',
          revertRequestRecord.reviewIssueCreatedTimestamp!.millisecondsSinceEpoch,
        ),
        // This could not possibly be landed at the time of entry into the database but we should check for null.
        _createIntegerQueryParameter(
          'REVIEW_ISSUE_LANDED_TIMESTAMP',
          (revertRequestRecord.reviewIssueLandedTimestamp != null)
              ? revertRequestRecord.reviewIssueLandedTimestamp!.millisecondsSinceEpoch
              : 0,
        ),
        _createStringQueryParameter(
          'REVIEW_ISSUE_CLOSED_BY',
          '',
        ),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Insert revert request $revertRequestRecord did not complete.',
      );
    }

    if (queryResponse.numDmlAffectedRows != null && int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw BigQueryException(
        'There was an error inserting $revertRequestRecord into the table.',
      );
    }
  }

  /// Select a specific revert request from the database.
  Future<RevertRequestRecord> selectRevertRequestByRevertPrNumber({
    required String projectId,
    required int prNumber,
    required String repository,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: selectRevertRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('REVERTING_PR_NUMBER', prNumber),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Get revert request with pr# $prNumber in repository $repository did not complete.',
      );
    }

    final List<TableRow>? tableRows = queryResponse.rows;
    if (tableRows == null || tableRows.isEmpty) {
      throw BigQueryException(
        'Could not find an entry for revert request with pr# $prNumber in repository $repository.',
      );
    }

    if (tableRows.length != 1) {
      throw BigQueryException(
        'More than one record was returned for revert request with pr# $prNumber in repository $repository.',
      );
    }

    final TableRow tableRow = tableRows.first;

    return RevertRequestRecord(
      organization: tableRow.f![0].v as String,
      repository: tableRow.f![1].v as String,
      author: tableRow.f![2].v as String,
      prNumber: int.parse(tableRow.f![3].v as String),
      prCommit: tableRow.f![4].v as String,
      prCreatedTimestamp: (tableRow.f![5].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![5].v as String))
          : null,
      prLandedTimestamp: (tableRow.f![6].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![6].v as String))
          : null,
      originalPrAuthor: tableRow.f![7].v as String,
      originalPrNumber: int.parse(tableRow.f![8].v as String),
      originalPrCommit: tableRow.f![9].v as String,
      originalPrCreatedTimestamp: (tableRow.f![10].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![10].v as String))
          : null,
      originalPrLandedTimestamp: (tableRow.f![11].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![11].v as String))
          : null,
      reviewIssueAssignee: tableRow.f![12].v as String,
      reviewIssueNumber: int.parse(tableRow.f![13].v as String),
      reviewIssueCreatedTimestamp: (tableRow.f![14].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![14].v as String))
          : null,
      reviewIssueLandedTimestamp: (tableRow.f![15].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![15].v as String))
          : null,
      reviewIssueClosedBy: tableRow.f![16].v as String,
    );
  }

  /// Query to select the open review issues for update.
  ///
  /// Issues are open if the review_issue_landed_timestamp is equal to 0.
  Future<List<RevertRequestRecord>> selectOpenReviewRequestIssueRecordsList({
    required String projectId,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: selectRevertRequestReviewIssuesDml,
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Get open review request issues records did not complete.',
      );
    }

    final List<TableRow>? tableRows = queryResponse.rows;
    if (tableRows == null || tableRows.isEmpty) {
      return <RevertRequestRecord>[];
    }

    final List<RevertRequestRecord> openReviewRequestIssues = [];
    for (TableRow tableRow in tableRows) {
      openReviewRequestIssues.add(
        RevertRequestRecord(
          reviewIssueAssignee: tableRow.f![0].v as String,
          reviewIssueNumber: int.parse(tableRow.f![1].v as String),
          reviewIssueCreatedTimestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![2].v as String)),
          reviewIssueLandedTimestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![3].v as String)),
          reviewIssueClosedBy: tableRow.f![4].v as String,
        ),
      );
    }

    return openReviewRequestIssues;
  }

  /// Query the database to update a revert review issue with the timestamp the
  /// issue was closed at and the person who closed the issue.
  Future<void> updateReviewRequestIssue({
    required String projectId,
    required DateTime reviewIssueLandedTimestamp,
    required int reviewIssueNumber,
    required String reviewIssueClosedBy,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: updateRevertRequestRecordReviewDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter(
          'REVIEW_ISSUE_LANDED_TIMESTAMP',
          reviewIssueLandedTimestamp.millisecondsSinceEpoch,
        ),
        _createIntegerQueryParameter(
          'REVIEW_ISSUE_NUMBER',
          reviewIssueNumber,
        ),
        _createStringQueryParameter(
          'REVIEW_ISSUE_CLOSED_BY',
          reviewIssueClosedBy,
        ),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Update of review issue $reviewIssueNumber did not complete.',
      );
    }

    if (queryResponse.numDmlAffectedRows != null && int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw BigQueryException(
        'There was an error updating revert request record review issue landed timestamp with review issue number $reviewIssueNumber.',
      );
    }
  }

  Future<void> deleteRevertRequestRecord({
    required String projectId,
    required int prNumber,
    required String repository,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: deleteRevertRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('REVERTING_PR_NUMBER', prNumber),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Delete revert request with pr# $prNumber in repository $repository did not complete.',
      );
    }

    if (queryResponse.numDmlAffectedRows == null || int.parse(queryResponse.numDmlAffectedRows!) == 0) {
      throw BigQueryException(
        'Could not find revert request with pr# $prNumber in repository $repository to delete.',
      );
    }

    if (int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw BigQueryException(
        'More than one row was deleted from the database for revert request with pr# $prNumber in repository $repository.',
      );
    }
  }

  /// Insert a new pull request record into the database.
  Future<void> insertPullRequestRecord({
    required String projectId,
    required PullRequestRecord pullRequestRecord,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: insertPullRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter(
          'PR_CREATED_TIMESTAMP',
          pullRequestRecord.prCreatedTimestamp!.millisecondsSinceEpoch,
        ),
        _createIntegerQueryParameter(
          'PR_LANDED_TIMESTAMP',
          pullRequestRecord.prLandedTimestamp!.millisecondsSinceEpoch,
        ),
        _createStringQueryParameter(
          'ORGANIZATION',
          pullRequestRecord.organization,
        ),
        _createStringQueryParameter(
          'REPOSITORY',
          pullRequestRecord.repository,
        ),
        _createStringQueryParameter(
          'AUTHOR',
          pullRequestRecord.author,
        ),
        _createIntegerQueryParameter(
          'PR_NUMBER',
          pullRequestRecord.prNumber,
        ),
        _createStringQueryParameter(
          'PR_COMMIT',
          pullRequestRecord.prCommit,
        ),
        _createStringQueryParameter(
          'PR_REQUEST_TYPE',
          pullRequestRecord.prRequestType,
        ),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Insert pull request $pullRequestRecord did not complete.',
      );
    }

    if (queryResponse.numDmlAffectedRows != null && int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw BigQueryException(
        'There was an error inserting $pullRequestRecord into the table.',
      );
    }
  }

  /// Select a specific pull request form the database.
  Future<PullRequestRecord> selectPullRequestRecordByPrNumber({
    required String projectId,
    required int prNumber,
    required String repository,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: selectPullRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('PR_NUMBER', prNumber),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Get pull request by pr# $prNumber in repository $repository did not complete.',
      );
    }

    final List<TableRow>? tableRows = queryResponse.rows;
    if (tableRows == null || tableRows.isEmpty) {
      throw BigQueryException(
        'Could not find an entry for pull request with pr# $prNumber in repository $repository.',
      );
    }

    if (tableRows.length != 1) {
      throw BigQueryException(
        'More than one record was returned for pull request with pr# $prNumber in repository $repository.',
      );
    }

    final TableRow tableRow = tableRows.first;

    return PullRequestRecord(
      prCreatedTimestamp: (tableRow.f![0].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![0].v as String))
          : null,
      prLandedTimestamp: (tableRow.f![1].v != null)
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(tableRow.f![1].v as String))
          : null,
      organization: tableRow.f![2].v as String,
      repository: tableRow.f![3].v as String,
      author: tableRow.f![4].v as String,
      prNumber: int.parse(tableRow.f![5].v as String),
      prCommit: tableRow.f![6].v as String,
      prRequestType: tableRow.f![7].v as String,
    );
  }

  Future<void> deletePullRequestRecord({
    required String projectId,
    required int prNumber,
    required String repository,
  }) async {
    final JobsResource jobsResource = await defaultJobs();

    final QueryRequest queryRequest = QueryRequest(
      query: deletePullRequestDml,
      queryParameters: <QueryParameter>[
        _createIntegerQueryParameter('PR_NUMBER', prNumber),
        _createStringQueryParameter('REPOSITORY', repository),
      ],
      useLegacySql: false,
    );

    final QueryResponse queryResponse = await jobsResource.query(queryRequest, projectId);
    if (!queryResponse.jobComplete!) {
      throw BigQueryException(
        'Delete pull request with pr# $prNumber in repository $repository did not complete.',
      );
    }

    if (queryResponse.numDmlAffectedRows == null || int.parse(queryResponse.numDmlAffectedRows!) == 0) {
      throw BigQueryException(
        'Could not find pull request with pr# $prNumber in repository $repository to delete.',
      );
    }

    if (int.parse(queryResponse.numDmlAffectedRows!) != 1) {
      throw BigQueryException(
        'More than one row was deleted from the database for pull request with pr# $prNumber in repository $repository.',
      );
    }
  }

  /// Create an int parameter for query substitution.
  QueryParameter _createIntegerQueryParameter(String name, int? value) {
    return QueryParameter(
      name: name,
      parameterType: QueryParameterType(type: 'INT64'),
      parameterValue: QueryParameterValue(value: value.toString()),
    );
  }

  /// Create a String parameter for query substitution.
  QueryParameter _createStringQueryParameter(String name, String? value) {
    return QueryParameter(
      name: name,
      parameterType: QueryParameterType(type: 'STRING'),
      parameterValue: QueryParameterValue(value: value),
    );
  }
}
