// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/validations/validation.dart';
import 'package:test/expect.dart';

import 'ci_successful_test_data.dart';

import 'package:auto_submit/validations/revert.dart';
import 'package:test/scaffolding.dart';

import '../utilities/utils.dart';
import '../utilities/mocks.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../requests/github_webhook_test_data.dart';

void main() {
  late FakeConfig config;
  FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  MockGitHub gitHub = MockGitHub();
  // late github.RepositorySlug slug;
  late Set<FailureDetail> failures;

  /// Setup objects needed across test groups.
  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    failures = <FailureDetail>{};
  });

  group('Pattern matching for revert text link', () {
    late Revert revert;

    setUp(() {
      revert = Revert(config: config);
    });

    test('Link extraction from description is successful.', () {
      // input, expected
      Map<String, String> tests = <String, String>{};
      tests['Reverts flutter/cocoon#123456'] = 'flutter/cocoon#123456';
      tests['Reverts    flutter/cocoon#123456'] = 'flutter/cocoon#123456';
      tests['Reverts flutter/flutter-intellij#123456'] = 'flutter/flutter-intellij#123456';
      tests['Reverts flutter/platform_tests#123456'] = 'flutter/platform_tests#123456';
      tests['Reverts flutter/.github#123456'] = 'flutter/.github#123456';
      tests['Reverts flutter/assets-for-api-docs#123456'] = 'flutter/assets-for-api-docs#123456';
      tests['Reverts flutter/flutter.github.io#123456'] = 'flutter/flutter.github.io#123456';
      tests['Reverts flutter/flutter_gallery_assets#123456'] = 'flutter/flutter_gallery_assets#123456';
      tests['reverts flutter/cocoon#12323'] = 'flutter/cocoon#12323';
      tests['reverts flutter/cocoon#223'] = 'flutter/cocoon#223';

      tests.forEach((key, value) {
        String? linkFound = revert.extractLinkFromText(key);
        assert(linkFound != null);
        assert(linkFound == value);
      });
    });

    test('Link extraction from description returns null', () {
      Map<String, String> tests = <String, String>{};
      tests['Revert flutter/cocoon#123456'] = '';
      tests['revert flutter/cocoon#123456'] = '';
      tests['Reverts flutter/cocoon#'] = '';
      tests['Reverts flutter123'] = '';

      tests.forEach((key, value) {
        String? linkFound = revert.extractLinkFromText(key);
        assert(linkFound == null);
      });
    });
  });
}
