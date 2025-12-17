// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../model/firestore/suppressed_test.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart'; // For Request
import '../request_handling/response.dart';
import '../service/firestore.dart';

/// Manually updates the test suppression status.
///
/// This endpoint allows authorized users to suppress or unsuppress a test.
///
/// Request parameters:
/// - `testName`: The name of the test to suppress/unsuppress.
/// - `repository`: The repository slug (e.g. `flutter/flutter`).
/// - `action`: `SUPPRESS` or `UNSUPPRESS`.
/// - `issueLink`: URL to the GitHub issue tracking the failure.
/// - `note`: Optional note describing the action.
final class UpdateTestSuppression extends ApiRequestHandler {
  const UpdateTestSuppression({
    required FirestoreService firestore,
    required super.config,
    required super.authenticationProvider,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _firestore = firestore,
       _now = now;

  final FirestoreService _firestore;
  final DateTime Function() _now;

  static const _paramTestName = 'testName';
  static const _paramRepository = 'repository';
  static const _paramAction = 'action';
  static const _paramIssueLink = 'issueLink';
  static const _paramNote = 'note';

  static const _actionSuppress = 'SUPPRESS';
  static const _actionUnsuppress = 'UNSUPPRESS';

  @override
  Future<Response> post(Request request) async {
    // Feature flag check
    if (!config.flags.dynamicTestSuppression) {
      throw const MethodNotAllowed('Tree status suppression is disabled.');
    }

    final body = await request.readBodyAsJson();
    checkRequiredParameters(body, [
      _paramTestName,
      _paramRepository,
      _paramAction,
      _paramIssueLink,
    ]);

    final testName = body[_paramTestName];
    if (testName is! String) {
      throw const BadRequestException(
        'Parameter "$_paramTestName" must be a string',
      );
    }

    final action = body[_paramAction];
    if (action is! String ||
        (action != _actionSuppress && action != _actionUnsuppress)) {
      throw const BadRequestException(
        'Parameter "$_paramAction" must be SUPPRESS or UNSUPPRESS',
      );
    }

    final issueLink = body[_paramIssueLink];
    if (issueLink is! String) {
      throw const BadRequestException(
        'Parameter "$_paramIssueLink" must be a string',
      );
    }

    final RepositorySlug repository;
    {
      final repositoryString = body[_paramRepository];
      if (repositoryString is! String) {
        throw const BadRequestException(
          'Parameter "$_paramRepository" must be a string',
        );
      }
      repository = RepositorySlug.full(repositoryString);
    }

    final note = body[_paramNote] ?? '';
    if (note is! String) {
      throw const BadRequestException(
        'Optional parameter "$_paramNote" must be a string',
      );
    }

    // Validate issue link
    final issueNumber = _parseIssueNumber(issueLink);
    if (issueNumber == null) {
      throw const BadRequestException(
        'Invalid issue link format, expected https://github.com/flutter/flutter/issues/1234',
      );
    }

    // Validate issue exists and is open if suppressing
    if (action == _actionSuppress) {
      final githubService = await config.createGithubService(repository);
      final issue = await githubService.getIssue(
        repository,
        issueNumber: issueNumber,
      );
      if (issue == null) {
        throw const BadRequestException('Issue not found.');
      }
      if (issue.state != 'open') {
        throw const BadRequestException(
          'Issue must be open to suppress a test.',
        );
      }
    }

    // Process suppression
    await _updateSuppression(
      testName: testName,
      repository: repository,
      action: action,
      issueLink: issueLink,
      note: note,
    );

    return Response.emptyOk;
  }

  int? _parseIssueNumber(String issueLink) {
    // Expected format: https://github.com/flutter/flutter/issues/123456
    final uri = Uri.tryParse(issueLink);
    if (uri == null ||
        uri.host != 'github.com' ||
        uri.pathSegments.length < 4 ||
        uri.pathSegments[uri.pathSegments.length - 2] != 'issues') {
      return null;
    }

    // Path segments: [flutter, flutter, issues, 123456]
    // Or just check the last segment if it is a number
    return int.tryParse(uri.pathSegments.last);
  }

  Future<void> _updateSuppression({
    required String testName,
    required RepositorySlug repository,
    required String action,
    required String issueLink,
    required String note,
  }) async {
    // Query for existing suppression - we assume there is at most one document
    // per (repo, name) based on business logic, though the DB constraint might
    // not strictly exist yet without unique index.
    final SuppressedTest? existingSuppression;
    {
      final previous = await SuppressedTest.getLatest(
        _firestore,
        repository.fullName,
        testName,
      );
      if (previous?.isSuppressed == false) {
        // Don't update old, closed tests.
        existingSuppression = null;
      } else {
        existingSuppression = previous;
      }
    }

    final isSuppressed = action == _actionSuppress;
    final now = _now().toUtc();

    // New or old doc; record an update
    final updateEntry = {
      SuppressedTest.updateFieldUser: authContext!.email,
      SuppressedTest.updateFieldUpdateTimestamp: now,
      SuppressedTest.updateFieldNote: note,
      SuppressedTest.updateFieldAction: action,
    };

    // Update an existing document
    if (existingSuppression != null) {
      final updatedSuppression = SuppressedTest(
        name: testName,
        repository: repository.fullName,
        issueLink: issueLink,
        isSuppressed: isSuppressed,
        createTimestamp: existingSuppression.createTimestamp,
        updates: [...existingSuppression.updates, updateEntry],
      )..name = existingSuppression.name; // We need to preserve the ID.

      await _firestore.batchWriteDocuments(
        BatchWriteRequest(
          writes: [
            Write(
              update: updatedSuppression,
              currentDocument: Precondition(exists: true),
            ),
          ],
        ),
        kDatabase,
      );
    } else {
      // Create new document
      if (action == _actionUnsuppress) {
        // Nothing to unsuppress.
        return;
      }

      final newSuppression = SuppressedTest(
        name: testName,
        repository: repository.fullName,
        issueLink: issueLink,
        isSuppressed: true,
        createTimestamp: now,
        updates: [updateEntry],
      );

      await _firestore.createDocument(
        newSuppression,
        collectionId: SuppressedTest.kCollectionId,
      );
    }
  }
}
