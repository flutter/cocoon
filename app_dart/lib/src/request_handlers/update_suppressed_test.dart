// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/test_suppression.dart'
    show SuppressingAction, TestSuppression;

/// Manually updates the test suppression status.
///
/// This endpoint allows authorized users to suppress or unsuppress a test.
///
/// Request parameters:
/// - `testName`: The name of the test to suppress/unsuppress.
/// - `repository`: The repository slug (e.g. `flutter/flutter`).
/// - `action`: `SUPPRESS` or `UNSUPPRESS`.
/// - `issueLink`: URL to the GitHub issue tracking the failure.
///    required if SUPPRESS
/// - `note`: Optional note describing the action.
final class UpdateSuppressedTest extends ApiRequestHandler {
  const UpdateSuppressedTest({
    required super.config,
    required super.authenticationProvider,
    required TestSuppression suppressionService,
  }) : _suppressionService = suppressionService;

  final TestSuppression _suppressionService;

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

    String? issueLink;

    // Validate issue exists and is open if suppressing
    if (action == _actionSuppress) {
      final link = body[_paramIssueLink];
      if (link is! String) {
        throw const BadRequestException(
          'Parameter "$_paramIssueLink" must be a string',
        );
      }
      issueLink = link;

      // Validate issue link
      final issueNumber = _parseIssueNumber(issueLink);
      if (issueNumber == null) {
        throw const BadRequestException(
          'Invalid issue link format, expected https://github.com/flutter/flutter/issues/1234',
        );
      }

      final githubService = await config.createGithubService(repository);
      final Issue? issue;
      try {
        issue = await githubService.getIssue(
          repository,
          issueNumber: issueNumber,
        );
      } catch (e) {
        throw BadRequestException('Error searching for issue: $e');
      }

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
    await _suppressionService.updateSuppression(
      testName: testName,
      repository: repository,
      action: action == 'UNSUPPRESS'
          ? SuppressingAction.unsuppress
          : SuppressingAction.suppress,
      issueLink: issueLink,
      email: authContext!.email,
      note: note,
    );

    log.info(
      'Test suppression update: $action $testName in $repository by ${authContext!.email}',
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
}
