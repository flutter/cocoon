// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/revert_issue_body_formatter.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  // Calls are made as they are done in git_cli_revert_method.dart.
  test('Allow nullable fields in formatter.', () {
    final PullRequest pullRequest = PullRequest(number: 123456, body: null, title: 'Interesting title.');
    const String sender = 'RevertAuthor';
    RevertIssueBodyFormatter? revertIssueBodyFormatter;
    expect(
      () => revertIssueBodyFormatter = RevertIssueBodyFormatter(
        slug: RepositorySlug('flutter', 'flutter'),
        originalPrNumber: pullRequest.number!,
        initiatingAuthor: sender,
        originalPrTitle: pullRequest.title,
        originalPrBody: pullRequest.body,
      ),
      returnsNormally,
    );
    revertIssueBodyFormatter!.format;
    expect(revertIssueBodyFormatter, isNotNull);
    expect(revertIssueBodyFormatter!.revertPrBody!.contains('No description provided.'), isTrue);
  });
}
