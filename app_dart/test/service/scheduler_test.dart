// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:gcloud/db.dart' as gcloud_db;
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/scheduler.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/utilities/mocks.dart';

const String singleDeviceLabTaskManifestYaml = '''
tasks:
  linux_test:
    stage: devicelab
    required_agent_capabilities: ["linux/android"]
''';

void main() {
  FakeConfig config;
  FakeDatastoreDB db;
  FakeHttpClient httpClient;
  Scheduler scheduler;

  Commit shaToCommit(String sha, {String branch = 'master'}) {
    return Commit(
      key: db.emptyKey.append(Commit, id: 'flutter/flutter/$branch/$sha'),
      sha: sha,
      branch: branch,
      timestamp: int.parse(sha),
    );
  }

  group('add commits', () {
    setUp(() {
      final MockTabledataResourceApi tabledataResourceApi = MockTabledataResourceApi();
      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) {
        return Future<TableDataInsertAllResponse>.value(null);
      });

      db = FakeDatastoreDB();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi, dbValue: db);
      httpClient = FakeHttpClient();
      httpClient.request.response.body = singleDeviceLabTaskManifestYaml;

      scheduler = Scheduler(
          config: config, datastore: DatastoreService(db, 2), httpClientProvider: () => httpClient, log: FakeLogging());
    });

    List<Commit> createCommitList(List<String> shas) {
      return List<Commit>.generate(
          shas.length,
          (int index) => Commit(
                author: 'Username',
                authorAvatarUrl: 'http://example.org/avatar.jpg',
                branch: 'master',
                key: db.emptyKey.append(Commit, id: 'flutter/flutter/master/${shas[index]}'),
                message: 'commit message',
                repository: 'flutter/flutter',
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
      expect(db.values.values.whereType<Task>().length, 2 * 5);
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
      expect(db.values.values.whereType<Task>().length, 2 * 5);
      // Check commits were added, but 3 was not
      expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
      expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
    });

    test('retries manifest download upon HTTP failure', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) {
        request.response.statusCode = retry == 0 ? HttpStatus.serviceUnavailable : HttpStatus.ok;
        retry++;
      };

      config.flutterBranchesValue = <String>['master'];
      await scheduler.loadDevicelabManifest(shaToCommit('123'));
      expect(retry, 2);
    });

    test('gives up devicelab manifest download after 3 tries', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;

      config.flutterBranchesValue = <String>['master'];
      httpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
      await expectLater(scheduler.loadDevicelabManifest(shaToCommit('123')), throwsA(isA<HttpStatusException>()));
      expect(retry, 3);
    });
  });

  group('add pull request', () {
    setUp(() {
      final MockTabledataResourceApi tabledataResourceApi = MockTabledataResourceApi();
      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) {
        return Future<TableDataInsertAllResponse>.value(null);
      });

      db = FakeDatastoreDB();
      config = FakeConfig(
        tabledataResourceApi: tabledataResourceApi,
        dbValue: db,
        flutterBranchesValue: <String>['master'],
      );
      httpClient = FakeHttpClient();
      httpClient.request.response.body = singleDeviceLabTaskManifestYaml;

      scheduler = Scheduler(
          config: config, datastore: DatastoreService(db, 2), httpClientProvider: () => httpClient, log: FakeLogging());
    });

    test('creates expected commit', () async {
      final PullRequest mergedPr = createPullRequest();
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
      final PullRequest mergedPr = createPullRequest();
      await scheduler.addPullRequest(mergedPr);

      expect(db.values.values.whereType<Commit>().length, 1);
      expect(db.values.values.whereType<Task>().length, 5);
    });

    test('does not schedule tasks against non-merged PRs', () async {
      final PullRequest notMergedPr = createPullRequest(merged: false);
      await scheduler.addPullRequest(notMergedPr);

      expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 0);
      expect(db.values.values.whereType<Task>().length, 0);
    });

    test('does not schedule tasks against already added PRs', () async {
      // Existing commits should not be duplicated.
      final Commit commit = shaToCommit('1');
      db.values[commit.key] = commit;

      final PullRequest alreadyLandedPr = createPullRequest(mergedCommitSha: '1');
      await scheduler.addPullRequest(alreadyLandedPr);

      expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 1);
      // No tasks should be scheduled as that is done on commit insert.
      expect(db.values.values.whereType<Task>().length, 0);
    });

    test('creates expected commit from release branch PR', () async {
      final PullRequest mergedPr = createPullRequest(branch: '1.26');
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
}

PullRequest createPullRequest({
  int id = 789,
  String branch = 'master',
  String repo = 'flutter/flutter',
  String authorLogin = 'dash',
  String authorAvatar = 'dashatar',
  String title = 'example message',
  int number = 123,
  DateTime mergedAt,
  String mergedCommitSha = 'abc',
  bool merged = true,
}) {
  mergedAt ??= DateTime.fromMillisecondsSinceEpoch(1);
  return PullRequest(
    id: id,
    title: title,
    number: number,
    mergedAt: mergedAt,
    base: PullRequestHead(
        ref: branch,
        repo: Repository(
          fullName: 'flutter/$repo',
          name: repo,
        )),
    user: User(
      login: authorLogin,
      avatarUrl: authorAvatar,
    ),
    mergeCommitSha: mergedCommitSha,
    merged: merged,
  );
}

String toSha(Commit commit) => commit.sha;

int toTimestamp(Commit commit) => commit.timestamp;
