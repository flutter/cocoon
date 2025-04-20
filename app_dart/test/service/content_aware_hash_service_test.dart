// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/github/workflow_job.dart';
import 'package:cocoon_service/src/service/content_aware_hash_service.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../model/github/workflow_job_data.dart';
import '../src/fake_config.dart';
import '../src/service/fake_github_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late MockGitHub github;
  late FakeGithubService githubService;
  late ContentAwareHashService cahs;

  setUp(() {
    github = MockGitHub();
    githubService = FakeGithubService(client: github);
    config = FakeConfig(githubClient: github, githubService: githubService);
    cahs = ContentAwareHashService(config: config);
  });

  group('hashFromWorkflowJobEvent', () {
    test('works as expected', () async {
      final job = workflowJobTemplate().toWorkflowJob();
      when(
        github.request(
          'GET',
          argThat(
            equals(
              'https://api.github.com/repos/flutter/flutter/check-runs/40533761873/annotations',
            ),
          ),
        ),
      ).thenAnswer((_) async => Response(goodAnnotation, 200));

      final hash = await cahs.hashFromWorkflowJobEvent(job);
      expect(hash, '65038ef4984b927fd1762ef01d35c5ecc34ff5f7');
    });

    test('ignores invalid annotations', () async {
      final job = workflowJobTemplate().toWorkflowJob();
      when(
        github.request(
          'GET',
          argThat(
            equals(
              'https://api.github.com/repos/flutter/flutter/check-runs/40533761873/annotations',
            ),
          ),
        ),
      ).thenAnswer((_) async => Response(nonsesnseAnnotation, 200));

      final hash = await cahs.hashFromWorkflowJobEvent(job);
      expect(hash, isNull);
    });

    group('fails validation when', () {
      setUp(() {
        when(
          github.request(
            'GET',
            argThat(
              equals(
                'https://api.github.com/repos/flutter/flutter/check-runs/40533761873/annotations',
              ),
            ),
          ),
        ).thenAnswer((_) async => Response('[{}]', 200));
      });

      test('action is not `completed`', () async {
        final job = workflowJobTemplate(action: 'in_progress').toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });

      test('repositroy is not `flutter/flutter`', () async {
        final job =
            workflowJobTemplate(
              repositoryFullName: 'flutter/fubar',
            ).toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });

      test('workflow name is not `generate-engine-content-hash`', () async {
        final job = workflowJobTemplate(name: 'issue-tracker').toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });

      test('workflow status is not `completed`', () async {
        final job =
            workflowJobTemplate(workflowStatus: 'queued').toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });

      test('workflow conclusion is not `success`', () async {
        final job =
            workflowJobTemplate(workflowConclusion: 'failure').toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });

      test(
        'workflowName is not `Generate a content aware hash for the Flutter Engine`',
        () async {
          final job =
              workflowJobTemplate(
                workflowName: 'Codefu Workflow',
              ).toWorkflowJob();
          expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
        },
      );

      test('head_bracnh is not `gh-readonly-queue', () async {
        final job = workflowJobTemplate(headBranch: 'master').toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });

      test('head_sha is not valid', () async {
        final job = workflowJobTemplate(headSha: 'Z' * 40).toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });

      test('sender is not `fluttergithubbot`', () async {
        final job =
            workflowJobTemplate(
              senderLogin: 'totallyfluttergithubbot',
            ).toWorkflowJob();
        expect(await cahs.hashFromWorkflowJobEvent(job), isNull);
      });
    });
  });
}

extension on String {
  WorkflowJobEvent toWorkflowJob() => WorkflowJobEvent.fromJson(
    json.decode(workflowJobTemplate()) as Map<String, Object?>,
  );
}

const goodAnnotation = r'''[
   {
      "message" : "{\"not_content_hash\": \"65038ef4984b927fd1762ef01d35c5ecc34ff5f7\"}"
   },
   {
      "annotation_level" : "notice",
      "blob_href" : "https://github.com/flutter/flutter/blob/ddb811621061c5ad2767ff4ac84b2be70b8e84bf/.github",
      "end_column" : null,
      "end_line" : 18,
      "message" : "{\"engine_content_hash\": \"65038ef4984b927fd1762ef01d35c5ecc34ff5f7\"}",
      "path" : ".github",
      "raw_details" : "",
      "start_column" : null,
      "start_line" : 18,
      "title" : ""
   }
]''';

const nonsesnseAnnotation = r'''[
   {},
   {
      "message" : "random string"
   },
   {
      "message" : "{\"some_other_content_hash\": \"65038ef4984b927fd1762ef01d35c5ecc34ff5f7\"}"
   },
]''';
