// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/revert/revert_issue_body_formatter.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  // Calls are made as they are done in git_cli_revert_method.dart.
  test('Allow nullable fields in formatter.', () {
    final pullRequest = PullRequest(
      number: 54,
      body: null,
      title: 'Interesting title.',
    );
    const sender = 'RevertAuthor';
    const reason = 'Revert reason: test xyz has began failing constantly.';
    const originalPrAuthor = 'caradune';
    final originalPrReviewers = <String>{'Mando', 'Grogu'};
    RevertIssueBodyFormatter? revertIssueBodyFormatter;
    expect(
      () =>
          revertIssueBodyFormatter = RevertIssueBodyFormatter(
            slug: RepositorySlug('flutter', 'flutter'),
            prToRevertNumber: pullRequest.number!,
            initiatingAuthor: sender,
            revertReason: reason,
            prToRevertAuthor: originalPrAuthor,
            prToRevertReviewers: originalPrReviewers,
            prToRevertTitle: pullRequest.title,
            prToRevertBody: pullRequest.body,
          ),
      returnsNormally,
    );
    revertIssueBodyFormatter!.format;
    expect(revertIssueBodyFormatter, isNotNull);
    expect(
      revertIssueBodyFormatter!.revertPrTitle,
      'Reverts "Interesting title. (#54)"',
    );
    expect(
      revertIssueBodyFormatter!.revertPrBody!.contains(
        'No description provided.',
      ),
      isTrue,
    );
    expect(
      revertIssueBodyFormatter!.formattedRevertPrBody!.contains(
        originalPrAuthor,
      ),
      isTrue,
    );
    expect(
      revertIssueBodyFormatter!.formattedRevertPrBody!.contains('Mando'),
      isTrue,
    );
  });
}
