// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/configuration/code_freeze_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/code_freeze.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';

void main() {
  late CodeFreeze codeFreeze;
  late FakeConfig config;
  late FakeGithubService githubService;
  late QueryResult queryResult;

  setUp(() {
    githubService = FakeGithubService();
    config = FakeConfig(githubService: githubService);
    queryResult = QueryResult();
    codeFreeze = CodeFreeze(config: config);
  });

  group('CodeFreeze', () {
    test('returns success when no freeze is active', () async {
      final pr = generatePullRequest();

      config.codeFreezeConfigurationValue = CodeFreezeConfiguration({});

      final result = await codeFreeze.validate(queryResult, pr);
      expect(result.result, isTrue);
      expect(result.action, Action.IGNORE_FAILURE);
    });

    test('blocks PR with frozen label', () async {
      final pr = generatePullRequest(labelName: 'f: material design');

      final criteria = FreezeCriteria(frozenLabels: {'f: material design'});
      config.codeFreezeConfigurationValue = CodeFreezeConfiguration({
        'flutter/flutter': criteria,
      });

      final result = await codeFreeze.validate(queryResult, pr);
      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message,
        contains(
          'blocked due to an active code freeze for the following labels: f: material design',
        ),
      );
    });

    test('blocks PR with frozen path', () async {
      final pr = generatePullRequest(prNumber: 123);

      final criteria = FreezeCriteria(
        frozenPaths: {'packages/flutter/lib/src/material/'},
      );
      config.codeFreezeConfigurationValue = CodeFreezeConfiguration({
        'flutter/flutter': criteria,
      });

      githubService.pullrequestFilesData = jsonEncode([
        {'filename': 'packages/flutter/lib/src/material/flat_button.dart'},
      ]);

      final result = await codeFreeze.validate(queryResult, pr);
      expect(result.result, isFalse);
      expect(result.action, Action.REMOVE_LABEL);
      expect(
        result.message,
        contains(
          'blocked due to an active code freeze for the following paths: packages/flutter/lib/src/material/',
        ),
      );
    });

    test('allows PR with no frozen label or path', () async {
      final pr = generatePullRequest(
        prNumber: 123,
        labelName: 'f: some other label',
      );

      final criteria = FreezeCriteria(
        frozenLabels: {'f: material design'},
        frozenPaths: {'packages/flutter/lib/src/material/'},
      );
      config.codeFreezeConfigurationValue = CodeFreezeConfiguration({
        'flutter/flutter': criteria,
      });

      githubService.pullrequestFilesData = jsonEncode([
        {'filename': 'packages/flutter/lib/src/widgets/framework.dart'},
      ]);

      final result = await codeFreeze.validate(queryResult, pr);
      expect(result.result, isTrue);
    });
  });
}
