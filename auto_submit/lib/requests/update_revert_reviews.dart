// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/model/big_query_revert_request_record.dart';
import 'package:auto_submit/service/bigquery.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../service/log.dart';
import '../server/authenticated_request_handler.dart';

class UpdateRevertReviews extends AuthenticatedRequestHandler {
  const UpdateRevertReviews({
    required super.config,
    required super.cronAuthProvider,
  });

  @override
  Future<Response> get() async {
    BigqueryService bigqueryService = await config.createBigQueryService();

    log.info('Updating closed revert request review issues in the database.');
    List<RevertRequestRecord> revertRequestRecords =
        await bigqueryService.selectOpenReviewRequestIssueRecordsList(projectId: 'flutter-dashboard');

    if (revertRequestRecords.isEmpty) {
      return Response.ok('No open revert reviews to update.');
    }

    GithubService githubService = await config.createGithubService(RepositorySlug('flutter', 'flutter'));

    for (RevertRequestRecord revertRequestRecord in revertRequestRecords) {
      await updateIssue(
        revertRequestRecord: revertRequestRecord,
        bigqueryService: bigqueryService,
        githubService: githubService,
      );
    }

    return Response.ok('Finished processing revert review updates.');
  }

  /// Update the review isse associated with the revert request if it has been
  /// closed.
  Future<bool> updateIssue({
    required RevertRequestRecord revertRequestRecord,
    required BigqueryService bigqueryService,
    required GithubService githubService,
  }) async {
    bool updated = false;
    log.info('Processing review issue# ${revertRequestRecord.reviewIssueNumber}.');
    try {
      // Get the revert review issue.
      Issue issue = await githubService.getIssue(
        slug: RepositorySlug('flutter', 'flutter'),
        issueNumber: revertRequestRecord.reviewIssueNumber!,
      );

      if (issue.isClosed) {
        log.info('Updating review issue# ${issue.number} in database.');
        await bigqueryService.updateReviewRequestIssue(
          projectId: 'flutter-dashboard',
          reviewIssueLandedTimestamp: issue.closedAt!,
          reviewIssueNumber: revertRequestRecord.reviewIssueNumber!,
          reviewIssueClosedBy: issue.closedBy!.login!,
        );
        log.info('Review issue# ${issue.number} updated successfully.');
        updated = true;
      }
    } on BigQueryException catch (exception) {
      log.warning(
        'An error occured while validating and updating review issue# ${revertRequestRecord.reviewIssueNumber}. Exception: ${exception.cause}',
      );
    }
    return updated;
  }
}
