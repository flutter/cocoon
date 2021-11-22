// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../model/github/checks_test_data.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

const String singleCiYaml = '''
enabled_branches:
  - master
targets:
  - name: Linux A
    scheduler: luci
  - name: Linux B
    enabled_branches:
      - stable
    scheduler: luci
  - name: Google Internal Roll
    presubmit: false
    scheduler: google_internal
''';

void main() {
  late CacheService cache;
  late FakeConfig config;
  late FakeDatastoreDB db;
  late MockClient httpClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late Scheduler scheduler;

  final PullRequest pullRequest = generatePullRequest(id: 42);

  Commit shaToCommit(String sha, {String branch = 'master'}) {
    return Commit(
      key: db.emptyKey.append(Commit, id: 'flutter/flutter/$branch/$sha'),
      repository: 'flutter/flutter',
      sha: sha,
      branch: branch,
      timestamp: int.parse(sha),
    );
  }

  group('Scheduler', () {
    setUp(() {
      final MockTabledataResource tabledataResource = MockTabledataResource();
      when(tabledataResource.insertAll(any, any, any, any)).thenAnswer((_) async {
        return TableDataInsertAllResponse();
      });

      cache = CacheService(inMemory: true);
      db = FakeDatastoreDB();
      config = FakeConfig(
        tabledataResource: tabledataResource,
        dbValue: db,
        githubService: FakeGithubService(),
        githubClient: MockGitHub(),
      );
      httpClient = MockClient((http.Request request) async {
        if (request.url.path.contains('.ci.yaml')) {
          return http.Response(singleCiYaml, 200);
        }
        throw Exception('Failed to find ${request.url.path}');
      });

      mockGithubChecksUtil = MockGithubChecksUtil();
      // Generate check runs based on the name hash code
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
          .thenAnswer((Invocation invocation) async => generateCheckRun(invocation.positionalArguments[2].hashCode));
      scheduler = Scheduler(
        cache: cache,
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
        githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
        httpClientProvider: () => httpClient,
        luciBuildService: FakeLuciBuildService(
          config,
          githubChecksUtil: mockGithubChecksUtil,
        ),
      );

      when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2}
        });
      });
    });

    group('add commits', () {
      List<Commit> createCommitList(
        List<String> shas, {
        String repo = 'flutter',
      }) {
        return List<Commit>.generate(
            shas.length,
            (int index) => Commit(
                  author: 'Username',
                  authorAvatarUrl: 'http://example.org/avatar.jpg',
                  branch: 'master',
                  key: db.emptyKey.append(Commit, id: 'flutter/$repo/master/${shas[index]}'),
                  message: 'commit message',
                  repository: 'flutter/$repo',
                  sha: shas[index],
                  timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(shas[index])).millisecondsSinceEpoch,
                ));
      }

      test('succeeds when GitHub returns no commits', () async {
        await scheduler.addCommits(<Commit>[]);
        expect(db.values, isEmpty);
      });

      test('inserts all relevant fields of the commit', () async {
        config.flutterBranchesValue = <String>['master'];
        expect(db.values.values.whereType<Commit>().length, 0);
        await scheduler.addCommits(createCommitList(<String>['1']));
        expect(db.values.values.whereType<Commit>().length, 1);
        final Commit commit = db.values.values.whereType<Commit>().single;
        expect(commit.repository, 'flutter/flutter');
        expect(commit.branch, 'master');
        expect(commit.sha, '1');
        expect(commit.timestamp, 1);
        expect(commit.author, 'Username');
        expect(commit.authorAvatarUrl, 'http://example.org/avatar.jpg');
        expect(commit.message, 'commit message');
      });

      test('skips scheduling for unsupported repos', () async {
        config.flutterBranchesValue = <String>['master'];
        await scheduler.addCommits(createCommitList(<String>['1'], repo: 'not-supported'));
        expect(db.values.values.whereType<Commit>().length, 0);
      });

      test('skips commits for which transaction commit fails', () async {
        config.flutterBranchesValue = <String>['master'];

        // Existing commits should not be duplicated.
        final Commit commit = shaToCommit('1');
        db.values[commit.key] = commit;

        db.onCommit = (List<gcloud_db.Model<dynamic>> inserts, List<gcloud_db.Key<dynamic>> deletes) {
          if (inserts.whereType<Commit>().where((Commit commit) => commit.sha == '3').isNotEmpty) {
            throw StateError('Commit failed');
          }
        };
        // Commits are expect from newest to oldest timestamps
        await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
        expect(db.values.values.whereType<Commit>().length, 3);
        // The 2 new commits are scheduled tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 2);
        // Check commits were added, but 3 was not
        expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
        expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
      });

      test('skips commits for which task transaction fails', () async {
        config.flutterBranchesValue = <String>['master'];

        // Existing commits should not be duplicated.
        final Commit commit = shaToCommit('1');
        db.values[commit.key] = commit;

        db.onCommit = (List<gcloud_db.Model<dynamic>> inserts, List<gcloud_db.Key<dynamic>> deletes) {
          if (inserts.whereType<Task>().where((Task task) => task.createTimestamp == 3).isNotEmpty) {
            throw StateError('Task failed');
          }
        };
        // Commits are expect from newest to oldest timestamps
        await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
        expect(db.values.values.whereType<Commit>().length, 3);
        // The 2 new commits are scheduled tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 2);
        // Check commits were added, but 3 was not
        expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
        expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
      });
    });

    group('add pull request', () {
      test('creates expected commit', () async {
        final PullRequest mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        final Commit commit = db.values.values.whereType<Commit>().single;
        expect(commit.repository, 'flutter/flutter');
        expect(commit.branch, 'master');
        expect(commit.sha, 'abc');
        expect(commit.timestamp, 1);
        expect(commit.author, 'dash');
        expect(commit.authorAvatarUrl, 'dashatar');
        expect(commit.message, 'example message');
      });

      test('schedules tasks against merged PRs', () async {
        final PullRequest mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 2);
      });

      test('does not schedule tasks against non-merged PRs', () async {
        final PullRequest notMergedPr = generatePullRequest(merged: false);
        await scheduler.addPullRequest(notMergedPr);

        expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 0);
        expect(db.values.values.whereType<Task>().length, 0);
      });

      test('does not schedule tasks against already added PRs', () async {
        // Existing commits should not be duplicated.
        final Commit commit = shaToCommit('1');
        db.values[commit.key] = commit;

        final PullRequest alreadyLandedPr = generatePullRequest(sha: '1');
        await scheduler.addPullRequest(alreadyLandedPr);

        expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 1);
        // No tasks should be scheduled as that is done on commit insert.
        expect(db.values.values.whereType<Task>().length, 0);
      });

      test('creates expected commit from release branch PR', () async {
        final PullRequest mergedPr = generatePullRequest(branch: '1.26');
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        final Commit commit = db.values.values.whereType<Commit>().single;
        expect(commit.repository, 'flutter/flutter');
        expect(commit.branch, '1.26');
        expect(commit.sha, 'abc');
        expect(commit.timestamp, 1);
        expect(commit.author, 'dash');
        expect(commit.authorAvatarUrl, 'dashatar');
        expect(commit.message, 'example message');
      });
    });

    group('process check run', () {
      test('rerequested triggers triggers a luci build', () async {
        when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async {
          return CheckRun.fromJson(const <String, dynamic>{
            'id': 1,
            'started_at': '2020-05-10T02:49:31Z',
            'check_suite': <String, dynamic>{'id': 2}
          });
        });
        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          jsonDecode(checkRunString) as Map<String, dynamic>,
        );
        expect(await scheduler.processCheckRun(checkRunEvent), true);
      });
    });

    group('presubmit', () {
      test('gets only enabled .ci.yaml builds', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response('''
enabled_branches:
  - master
targets:
  - name: Linux A
    scheduler: luci
  - name: Linux B
    scheduler: luci
    enabled_branches:
      - stable
  - name: Linux C
    scheduler: luci
    enabled_branches:
      - master
    presubmit: true
  - name: Linux D
    scheduler: luci
    bringup: true
  - name: Google-internal roll
    scheduler: google_internal
    enabled_branches:
      - master
          ''', 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        config.luciBuildersValue = <LuciBuilder>[];
        final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(pullRequest);
        expect(presubmitTargets.map((Target target) => target.value.name).toList(),
            containsAll(<String>['Linux A', 'Linux C']));
      });

      test('checks for release branches', () async {
        const String branch = 'flutter-1.24-candidate.1';
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response('''
enabled_branches:
  - master
targets:
  - name: Linux A
    scheduler: luci
          ''', 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        config.luciBuildersValue = <LuciBuilder>[];
        expect(scheduler.getPresubmitTargets(generatePullRequest(branch: branch)),
            throwsA(predicate((Exception e) => e.toString().contains('$branch is not enabled'))));
      });

      test('triggers expected presubmit build checks', () async {
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
              .captured,
          <dynamic>[
            'ci.yaml validation',
            const CheckRunOutput(
                title: '.ci.yaml validation',
                summary: 'If this check is stuck pending, push an empty commit to retrigger the checks'),
            'Linux A',
            null,
          ],
        );
      });

      test('ci.yaml validation passes with default config', () async {
        when(mockGithubChecksUtil.getCheckRun(any, any, any))
            .thenAnswer((Invocation invocation) async => createCheckRun(id: 0));
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
            verify(mockGithubChecksUtil.updateCheckRun(any, any, any,
                    status: captureAnyNamed('status'),
                    conclusion: captureAnyNamed('conclusion'),
                    output: anyNamed('output')))
                .captured,
            <dynamic>[CheckRunStatus.completed, CheckRunConclusion.success]);
      });

      test('ci.yaml validation passes with retry', () async {
        bool retried = false;
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            if (retried) {
              return http.Response(singleCiYaml, HttpStatus.ok);
            }
            retried = true;
            return http.Response('FAILURE', HttpStatus.internalServerError);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        when(mockGithubChecksUtil.getCheckRun(any, any, any))
            .thenAnswer((Invocation invocation) async => createCheckRun(id: 0));
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
            verify(mockGithubChecksUtil.updateCheckRun(any, any, any,
                    status: captureAnyNamed('status'),
                    conclusion: captureAnyNamed('conclusion'),
                    output: anyNamed('output')))
                .captured,
            <dynamic>[CheckRunStatus.completed, CheckRunConclusion.success]);
      });

      test('ci.yaml validation fails with empty config', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response('', HttpStatus.ok);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
            verify(mockGithubChecksUtil.updateCheckRun(any, any, any,
                    status: captureAnyNamed('status'),
                    conclusion: captureAnyNamed('conclusion'),
                    output: anyNamed('output')))
                .captured,
            <dynamic>[CheckRunStatus.completed, CheckRunConclusion.failure]);
      });

      test('ci.yaml validation fails on not enabled branch', () async {
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
            verify(mockGithubChecksUtil.updateCheckRun(any, any, any,
                    status: captureAnyNamed('status'),
                    conclusion: captureAnyNamed('conclusion'),
                    output: anyNamed('output')))
                .captured,
            <dynamic>[CheckRunStatus.completed, CheckRunConclusion.failure]);
      });

      test('ci.yaml validation fails with config with unknown dependencies', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response('''
enabled_branches:
  - master
targets:
  - name: A
    builder: Linux A
    dependencies:
      - B
          ''', 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
            verify(mockGithubChecksUtil.updateCheckRun(any, any, any,
                    status: anyNamed('status'), conclusion: anyNamed('conclusion'), output: captureAnyNamed('output')))
                .captured
                .first
                .text,
            'FormatException: ERROR: A depends on B which does not exist');
      });

      test('retries only triggers failed builds only', () async {
        final MockBuildBucketClient mockBuildbucket = MockBuildBucketClient();
        scheduler = Scheduler(
          cache: cache,
          config: config,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
            buildbucket: mockBuildbucket,
          ),
        );
        when(mockBuildbucket.batch(any)).thenAnswer((_) async => BatchResponse(
              responses: <Response>[
                Response(
                  searchBuilds: SearchBuildsResponse(
                    builds: <Build>[
                      generateBuild(1000, name: 'Linux', bucket: 'try'),
                      generateBuild(2000, name: 'Linux Coverage', bucket: 'try'),
                      generateBuild(3000, name: 'Mac', bucket: 'try', status: Status.scheduled),
                      generateBuild(4000, name: 'Windows', bucket: 'try', status: Status.started),
                      generateBuild(5000, name: 'Linux A', bucket: 'try', status: Status.failure)
                    ],
                  ),
                ),
              ],
            ));
        when(mockBuildbucket.scheduleBuild(any))
            .thenAnswer((_) async => generateBuild(5001, name: 'Linux A', bucket: 'try', status: Status.scheduled));
        // Only Linux A should be retried
        final Map<String, CheckRun> checkRuns = <String, CheckRun>{
          'Linux': createCheckRun(name: 'Linux', id: 100),
          'Linux Coverage': createCheckRun(name: 'Linux Coverage', id: 200),
          'Mac': createCheckRun(name: 'Mac', id: 300, status: CheckRunStatus.queued),
          'Windows': createCheckRun(name: 'Windows', id: 400, status: CheckRunStatus.inProgress),
          'Linux A': createCheckRun(name: 'Linux A', id: 500),
        };
        when(mockGithubChecksUtil.allCheckRuns(any, any)).thenAnswer((_) async {
          return checkRuns;
        });

        final CheckSuiteEvent checkSuiteEvent =
            CheckSuiteEvent.fromJson(jsonDecode(checkSuiteTemplate('rerequested')) as Map<String, dynamic>);
        await scheduler.retryPresubmitTargets(
          pullRequest: pullRequest,
          checkSuiteEvent: checkSuiteEvent,
        );
        final List<dynamic> retriedBuildRequests = verify(mockBuildbucket.scheduleBuild(captureAny)).captured;
        expect(retriedBuildRequests.length, 1);
        final ScheduleBuildRequest retryRequest = retriedBuildRequests.first as ScheduleBuildRequest;
        expect(retryRequest.builderId.builder, 'Linux A');
      });
    });
  });
}

CheckRun createCheckRun({String? name, required int id, CheckRunStatus status = CheckRunStatus.completed}) {
  final int externalId = id * 2;
  final String checkRunJson =
      '{"name": "$name", "id": $id, "external_id": "{$externalId}", "status": "$status", "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 456}}';
  return CheckRun.fromJson(jsonDecode(checkRunJson) as Map<String, dynamic>);
}

String toSha(Commit commit) => commit.sha!;

int toTimestamp(Commit commit) => commit.timestamp!;
