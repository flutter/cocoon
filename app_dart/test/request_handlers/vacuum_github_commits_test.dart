// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/request_handlers/vacuum_github_commits.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late FakeDatastoreDB db;
  late ApiRequestHandlerTester tester;
  late FakeFirestoreService firestore;
  late VacuumGithubCommits handler;

  /// SHAs that are returned by FakeGithubService.listCommitsBranch.
  late List<String> fakeGithubCommitShas;
  List<RepositoryCommit> generateCommitsFromFakeGithubCommitShas() {
    final commits = <RepositoryCommit>[];
    for (var sha in fakeGithubCommitShas) {
      final author =
          User()
            ..login = 'Username'
            ..avatarUrl = 'http://example.org/avatar.jpg';
      final committer = GitCommitUser(
        'Username',
        'Username@abc.com',
        DateTime.fromMillisecondsSinceEpoch(int.parse(sha)),
      );
      final gitCommit =
          GitCommit()
            ..message = 'commit message'
            ..committer = committer;
      commits.add(
        RepositoryCommit()
          ..sha = sha
          ..author = author
          ..commit = gitCommit,
      );
    }
    return commits;
  }

  Commit shaToCommit(String sha, String branch, RepositorySlug slug) {
    return Commit(
      key: db.emptyKey.append(Commit, id: '${slug.fullName}/$branch/$sha'),
      repository: slug.fullName,
      sha: sha,
      branch: branch,
      timestamp: int.parse(sha),
    );
  }

  setUp(() {
    final githubService = FakeGithubService();
    final tabledataResourceApi = MockTabledataResource();
    firestore = FakeFirestoreService();

    // ignore: discarded_futures
    when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((
      _,
    ) async {
      return TableDataInsertAllResponse();
    });

    db = FakeDatastoreDB();
    config = FakeConfig(
      bigqueryService: BigqueryService.forTesting(
        tabledataResourceApi,
        MockJobsResource(),
      ),
      githubService: githubService,
      firestoreService: firestore,
      dbValue: db,
      supportedBranchesValue: ['master'],
      supportedReposValue: {Config.flutterSlug},
    );

    final auth = FakeDashboardAuthentication();
    final scheduler = FakeScheduler(config: config);
    tester = ApiRequestHandlerTester();
    handler = VacuumGithubCommits(
      config: config,
      authenticationProvider: auth,
      scheduler: scheduler,
    );

    githubService.listCommitsBranch = (_, _) {
      return generateCommitsFromFakeGithubCommitShas();
    };
  });

  test('succeeds when GitHub returns no commits', () async {
    fakeGithubCommitShas = <String>[];
    config.supportedBranchesValue = <String>['master'];
    final body = await tester.get<Body>(handler);
    expect(db.values, isEmpty);
    expect(await body.serialize().toList(), isEmpty);
  });

  test('does not fail on empty commit list', () async {
    fakeGithubCommitShas = <String>[];
    expect(db.values.values.whereType<Commit>().length, 0);
    await tester.get<Body>(handler);
    expect(db.values.values.whereType<Commit>().length, 0);
  });

  test('does not add recent commits', () async {
    fakeGithubCommitShas = <String>['${DateTime.now().millisecondsSinceEpoch}'];

    expect(db.values.values.whereType<Commit>().length, 0);
    await tester.get<Body>(handler);
    expect(db.values.values.whereType<Commit>().length, 0);
  });

  test('inserts all relevant fields of the commit', () async {
    fakeGithubCommitShas = <String>['1'];
    expect(db.values.values.whereType<Commit>().length, 0);
    await tester.get<Body>(handler);
    expect(
      db.values.values.whereType<Commit>().length,
      config.supportedRepos.length,
    );
    final commits = db.values.values.whereType<Commit>().toList();
    final commit = commits.first;
    expect(commit.repository, 'flutter/flutter');
    expect(commit.branch, 'master');
    expect(commit.sha, '1');
    expect(commit.timestamp, 1);
    expect(commit.author, 'Username');
    expect(commit.authorAvatarUrl, 'http://example.org/avatar.jpg');
    expect(commit.message, 'commit message');
  });

  test('skips commits for which transaction commit fails', () async {
    fakeGithubCommitShas = <String>['2', '3', '4'];

    /// This test is simulating an existing branch, which must already
    /// have at least one commit in the datastore.
    final commit = shaToCommit('1', 'master', Config.flutterSlug);
    db.values[commit.key] = commit;

    db.onCommit = (
      List<gcloud_db.Model<dynamic>> inserts,
      List<gcloud_db.Key<dynamic>> deletes,
    ) {
      if (inserts
          .whereType<Commit>()
          .where((Commit commit) => commit.sha == '3')
          .isNotEmpty) {
        throw StateError('Commit failed');
      }
    };
    await expectLater(tester.get<Body>(handler), throwsA(isStateError));

    expect(
      db.values.values.whereType<Commit>().map<String>(toSha),
      unorderedEquals(['1', '4']),
    );
  });
}

String toSha(Commit commit) => commit.sha!;
