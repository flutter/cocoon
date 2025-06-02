// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/content_aware_hash_builds.dart';
import 'package:cocoon_service/src/model/github/workflow_job.dart';
import 'package:cocoon_service/src/service/content_aware_hash_service.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../model/github/workflow_job_data.dart';
import '../src/fake_config.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_github_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late MockGitHub github;
  late FakeGithubService githubService;
  late ContentAwareHashService cahs;
  late FakeFirestoreService firestoreService;

  setUp(() {
    github = MockGitHub();
    githubService = FakeGithubService(client: github);
    config = FakeConfig(githubClient: github, githubService: githubService);
    firestoreService = FakeFirestoreService();
    cahs = ContentAwareHashService(config: config, firestore: firestoreService);
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
      ).thenAnswer((_) async => Response(goodAnnotation(), 200));

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

  group('processWorkflowJob', () {
    test('creates tracking document and returns build status.', () async {
      when(github.request('GET', any)).thenAnswer(
        (_) async => Response(goodAnnotation(contentHash: '1' * 40), 200),
      );

      final job = workflowJobTemplate(headSha: 'a' * 40).toWorkflowJob();
      final result = await cahs.processWorkflowJob(job);
      expect(result, (
        status: MergeQueueHashStatus.build,
        contentHash: '1111111111111111111111111111111111111111',
      ));
      expect(
        firestoreService,
        existsInStorage(ContentAwareHashBuilds.metadata, [
          isContentAwareHashBuilds
              .hasCommitSha('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
              .hasContentHash('1' * 40)
              .hasStatus(BuildStatus.inProgress)
              .hasWaitingShas([]),
        ]),
      );
    });

    test('returns `complete` if artifacts exist', () async {
      when(github.request('GET', any)).thenAnswer(
        (_) async => Response(goodAnnotation(contentHash: '1' * 40), 200),
      );

      firestoreService.putDocument(
        ContentAwareHashBuilds(
          createdOn: DateTime.now(),
          contentHash: '1' * 40,
          commitSha: 'a' * 40,
          buildStatus: BuildStatus.success,
          waitingShas: [],
        ),
      );

      final job = workflowJobTemplate(headSha: 'b' * 40).toWorkflowJob();
      final result = await cahs.processWorkflowJob(job);
      expect(result, (
        contentHash: '1111111111111111111111111111111111111111',
        status: MergeQueueHashStatus.complete,
      ));
    });

    test('stacks multiple builds in one doc', () async {
      when(github.request('GET', any)).thenAnswer(
        (_) async => Response(goodAnnotation(contentHash: '1' * 40), 200),
      );

      var job = workflowJobTemplate(headSha: 'a' * 40).toWorkflowJob();
      await cahs.processWorkflowJob(job);

      job = workflowJobTemplate(headSha: 'b' * 40).toWorkflowJob();
      final result = await cahs.processWorkflowJob(job);
      expect(result, (
        contentHash: '1111111111111111111111111111111111111111',
        status: MergeQueueHashStatus.wait,
      ));

      expect(
        firestoreService,
        existsInStorage(ContentAwareHashBuilds.metadata, [
          isContentAwareHashBuilds
              .hasCommitSha('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
              .hasContentHash('1' * 40)
              .hasStatus(BuildStatus.inProgress)
              .hasWaitingShas(['b' * 40]),
        ]),
      );
    });

    test('handles rollbacks', () async {
      firestoreService.failOnTransactionCommit(clearAfter: true);
      when(github.request('GET', any)).thenAnswer((_) async {
        return Response(goodAnnotation(contentHash: '1' * 40), 200);
      });

      var job = workflowJobTemplate(headSha: 'a' * 40).toWorkflowJob();
      await cahs.processWorkflowJob(job);

      job = workflowJobTemplate(headSha: 'b' * 40).toWorkflowJob();
      final result = await cahs.processWorkflowJob(job);
      expect(result, (
        contentHash: '1111111111111111111111111111111111111111',
        status: MergeQueueHashStatus.wait,
      ));

      expect(
        firestoreService,
        existsInStorage(ContentAwareHashBuilds.metadata, [
          isContentAwareHashBuilds
              .hasCommitSha('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
              .hasContentHash('1' * 40)
              .hasStatus(BuildStatus.inProgress)
              .hasWaitingShas(['b' * 40]),
        ]),
      );
    });

    test('handles abject failures', () async {
      firestoreService.failOnTransactionCommit(clearAfter: false);
      when(github.request('GET', any)).thenAnswer((_) async {
        return Response(goodAnnotation(contentHash: '1' * 40), 200);
      });

      var job = workflowJobTemplate(headSha: 'a' * 40).toWorkflowJob();
      await cahs.processWorkflowJob(
        job,
        retry: const RetryOptions(maxAttempts: 1, delayFactor: Duration.zero),
      );

      job = workflowJobTemplate(headSha: 'b' * 40).toWorkflowJob();
      final result = await cahs.processWorkflowJob(
        job,
        retry: const RetryOptions(maxAttempts: 5, maxDelay: Duration.zero),
      );
      expect(result, (contentHash: '', status: MergeQueueHashStatus.error));
    });
  });

  group('markArtifactsAsComplete', () {
    setUp(() {
      firestoreService.putDocument(
        ContentAwareHashBuilds(
          createdOn: DateTime.now(),
          contentHash: '1' * 40,
          commitSha: 'a' * 40,
          buildStatus: BuildStatus.inProgress,
          waitingShas: ['b' * 40, 'c' * 40, 'd' * 40],
        ),
      );
    });

    test('does what it says on the tin', () async {
      final shas = await cahs.completeArtifacts(
        commitSha: 'a' * 40,
        successful: true,
      );
      expect(shas, ['b' * 40, 'c' * 40, 'd' * 40]);
      expect(
        firestoreService,
        existsInStorage(ContentAwareHashBuilds.metadata, [
          isContentAwareHashBuilds
              .hasCommitSha('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
              .hasContentHash('1' * 40)
              .hasStatus(BuildStatus.success),
        ]),
      );
    });

    test('does not complete already completed', () async {
      firestoreService.putDocument(
        ContentAwareHashBuilds(
          createdOn: DateTime.now(),
          contentHash: '1' * 40,
          commitSha: 'a' * 40,
          buildStatus: BuildStatus.success,
          waitingShas: ['b' * 40, 'c' * 40, 'd' * 40],
        ),
      );
      final shas = await cahs.completeArtifacts(
        commitSha: 'a' * 40,
        successful: true,
        maxAttempts: 1,
      );
      expect(shas, isEmpty);
      expect(firestoreService.rollbacks, hasLength(1));
      expect(
        firestoreService,
        existsInStorage(ContentAwareHashBuilds.metadata, [
          isContentAwareHashBuilds
              .hasCommitSha('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
              .hasContentHash('1' * 40)
              .hasStatus(BuildStatus.success),
        ]),
      );
    });

    test('handles abject failures', () async {
      firestoreService.failOnTransactionCommit(clearAfter: false);
      final shas = await cahs.completeArtifacts(
        commitSha: 'a' * 40,
        successful: true,
        maxAttempts: 1,
      );
      expect(shas, isEmpty);
      expect(
        firestoreService,
        existsInStorage(ContentAwareHashBuilds.metadata, [
          isContentAwareHashBuilds
              .hasCommitSha('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
              .hasContentHash('1' * 40)
              .hasStatus(BuildStatus.inProgress),
        ]),
      );
    });

    test('TEMP: ignores unmatched shas (dual-builds)', () async {
      final shas = await cahs.completeArtifacts(
        commitSha: 'b' * 40,
        successful: true,
      );
      expect(shas, isEmpty);
      expect(
        firestoreService,
        existsInStorage(ContentAwareHashBuilds.metadata, [
          isContentAwareHashBuilds
              .hasCommitSha('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
              .hasContentHash('1' * 40)
              .hasStatus(BuildStatus.inProgress),
        ]),
      );

      expect(
        log,
        bufferedLoggerOf(
          contains(
            logThat(
              message: equals(
                'CAHS(commitSha: ${'b' * 40}): no matching hash found',
              ),
              severity: atMostInfo,
            ),
          ),
        ),
      );
    });
  });
}

extension on String {
  WorkflowJobEvent toWorkflowJob() =>
      WorkflowJobEvent.fromJson(json.decode(this) as Map<String, Object?>);
}

String goodAnnotation({
  String contentHash = '65038ef4984b927fd1762ef01d35c5ecc34ff5f7',
}) => json.encode([
  {
    'message':
        '{"not_content_hash": "65038ef4984b927fd1762ef01d35c5ecc34ff5f7"}',
  },
  {
    'annotation_level': 'notice',
    'blob_href':
        'https://github.com/flutter/flutter/blob/ddb811621061c5ad2767ff4ac84b2be70b8e84bf/.github',
    'end_column': null,
    'end_line': 18,
    'message': '{"engine_content_hash": "$contentHash"}',
    'path': '.github',
    'raw_details': '',
    'start_column': null,
    'start_line': 18,
    'title': '',
  },
]);

const nonsesnseAnnotation = r'''[
   {},
   {
      "message" : "random string"
   },
   {
      "message" : "{\"some_other_content_hash\": \"65038ef4984b927fd1762ef01d35c5ecc34ff5f7\"}"
   },
]''';
