// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' hide PullRequest;
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../utilities/utils.dart';
import '../utilities/mocks.dart';

void main() {
  late FakeConfig config;
  late CiSuccessful ciSuccessful;
  late FakeGithubService githubService;
  late RepositorySlug slug;

  setUp(() {
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(githubService: githubService);
    ciSuccessful = CiSuccessful(config: config);
    slug = RepositorySlug('flutter', 'cocoon');
  });

  test('returns correct message when validation fails', () async {
    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    githubService.checkRunsData = failedCheckRunsMock;
    final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
    QueryResult queryResult = createQueryResult(flutterRequest);

    final ValidationResult validationResult = await ciSuccessful.validate(queryResult, pullRequest);

    expect(validationResult.result, false);
    expect(validationResult.message,
        '- The status or check suite [failed_checkrun](https://example.com) has failed. Please fix the issues identified (or deflake) before re-applying this label.\n');
  });
}
