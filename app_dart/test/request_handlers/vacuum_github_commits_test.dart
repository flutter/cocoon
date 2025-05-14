// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as fs;
import 'package:cocoon_service/src/request_handlers/vacuum_github_commits.dart';
import 'package:cocoon_service/src/service/big_query.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
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

    config = FakeConfig(
      githubService: githubService,
      supportedBranchesValue: ['master'],
      supportedReposValue: {Config.flutterSlug},
    );

    final auth = FakeDashboardAuthentication();
    final scheduler = FakeScheduler(
      config: config,
      firestore: firestore,
      bigQuery: BigQueryService.forTesting(
        tabledataResourceApi,
        MockJobsResource(),
      ),
    );
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
    fakeGithubCommitShas = [];
    config.supportedBranchesValue = ['master'];
    final body = await tester.get(handler);

    expect(firestore, existsInStorage(fs.Commit.metadata, isEmpty));
    expect(await body.body.toList(), isEmpty);
  });

  test('succeeds on specific repo and branch set', () async {
    fakeGithubCommitShas = ['123'];
    config.supportedReposValue = {RepositorySlug('flutter', 'cocoon')};

    tester.request.uri = tester.request.uri.replace(
      queryParameters: {'repo': 'flutter/cocoon', 'branch': 'a-new-branch'},
    );

    await tester.get(handler);
    expect(
      firestore,
      existsInStorage(fs.Commit.metadata, [
        isCommit
            .hasSha('123')
            .hasRepositoryPath('flutter/cocoon')
            .hasBranch('a-new-branch'),
      ]),
    );
  });

  test('does not fail on empty commit list', () async {
    fakeGithubCommitShas = [];
    expect(firestore, existsInStorage(fs.Commit.metadata, isEmpty));
    await tester.get(handler);
    expect(firestore, existsInStorage(fs.Commit.metadata, isEmpty));
  });

  test('does not add recent commits', () async {
    fakeGithubCommitShas = ['${DateTime.now().millisecondsSinceEpoch}'];

    expect(firestore, existsInStorage(fs.Commit.metadata, isEmpty));
    await tester.get(handler);
    expect(firestore, existsInStorage(fs.Commit.metadata, isEmpty));
  });

  test('inserts all relevant fields of the commit', () async {
    fakeGithubCommitShas = ['1'];
    expect(firestore, existsInStorage(fs.Commit.metadata, isEmpty));
    await tester.get(handler);
    expect(
      firestore,
      existsInStorage(
        fs.Commit.metadata,
        hasLength(config.supportedRepos.length),
      ),
    );
  });
}
