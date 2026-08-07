// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';

import '../model/firestore/suppressed_test.dart';
import 'firestore.dart';
import 'test_suppression.dart';

/// Processes GitHub issue events to unsuppress or re-suppress matching tests.
final class IssueService {
  const IssueService({
    required this.firestore,
    required this.suppressionService,
  });

  final FirestoreService firestore;
  final TestSuppression suppressionService;

  /// Re-opens or closes suppressed tests matching a GitHub [IssueEvent].
  Future<void> handleIssueEvent(IssueEvent event) async {
    if (event.issue?.htmlUrl case final issueUrl? when issueUrl.isNotEmpty) {
      switch (event.action) {
        case 'closed':
          await _handleIssueClosed(event, issueUrl);
        case 'reopened':
          await _handleIssueReopened(event, issueUrl);
        case final action:
          log.debug('Ignoring issue event action: $action');
      }
      return;
    }
    log.debug('IssueEvent has no htmlUrl; skipping.');
  }

  Future<void> _handleIssueClosed(IssueEvent event, String issueUrl) async {
    final docs = await SuppressedTest.getByIssueLink(firestore, issueUrl);
    final processed = <String>{};

    for (final doc in docs) {
      // Tests can be suppressed at different times; we only need to handle
      // this event once per unique test.
      final key = '${doc.repository}/${doc.testName}';
      if (!processed.add(key)) {
        continue;
      }

      final latest = await SuppressedTest.getLatest(
        firestore,
        doc.repository,
        doc.testName,
      );
      if (latest == null ||
          latest.issueLink != issueUrl ||
          !latest.isSuppressed) {
        continue;
      }

      log.info(
        'Unsuppressing test ${doc.testName} in ${doc.repository} due to issue closed ($issueUrl)',
      );
      await suppressionService.updateSuppression(
        testName: doc.testName,
        email: event.sender?.login ?? 'github-webhook',
        repository: RepositorySlug.full(doc.repository),
        action: SuppressingAction.unsuppress,
        note: 'Automatic unsuppression: issue $issueUrl was closed.',
      );
    }
  }

  Future<void> _handleIssueReopened(IssueEvent event, String issueUrl) async {
    final docs = await SuppressedTest.getByIssueLink(firestore, issueUrl);
    final processed = <String>{};

    for (final doc in docs) {
      // Tests can be suppressed at different times; we only need to handle
      // this event once per unique test.
      final key = '${doc.repository}/${doc.testName}';
      if (!processed.add(key)) {
        continue;
      }

      final latest = await SuppressedTest.getLatest(
        firestore,
        doc.repository,
        doc.testName,
      );
      if (latest == null ||
          latest.issueLink != issueUrl ||
          latest.isSuppressed) {
        continue;
      }

      log.info(
        'Re-suppressing test ${doc.testName} in ${doc.repository} due to issue reopened ($issueUrl)',
      );
      await suppressionService.updateSuppression(
        testName: doc.testName,
        email: event.sender?.login ?? 'github-webhook',
        repository: RepositorySlug.full(doc.repository),
        action: SuppressingAction.suppress,
        issueLink: issueUrl,
        note: 'Automatic re-suppression: issue $issueUrl was reopened.',
      );
    }
  }
}
