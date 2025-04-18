// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as fs;
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.mocks.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late FakeDatastoreDB db;
  late CommitService commitService;
  late MockGithubService githubService;
  late MockRepositoriesService repositories;
  late MockGitHub github;
  late FakeFirestoreService firestore;

  const owner = 'flutter';
  const repository = 'flutter';
  const branch = 'coolest-branch';
  const sha = '1234';
  const message = 'Adding null safety';
  const avatarUrl = 'https://avatars.githubusercontent.com/u/fake-user-num';
  const username = 'AwesomeGithubUser';
  const dateTimeAsString = '2023-08-18T19:27:00Z';

  setUp(() {
    db = FakeDatastoreDB();
    github = MockGitHub();
    githubService = MockGithubService();
    firestore = FakeFirestoreService();
    when(githubService.github).thenReturn(github);
    repositories = MockRepositoriesService();
    when(github.repositories).thenReturn(repositories);
    config = FakeConfig(
      dbValue: db,
      firestoreService: firestore,
      githubService: githubService,
    );
    commitService = CommitService(config: config);
  });

  group('handleCreateGithubRequest', () {
    test('adds commit to db if it does not exist in the datastore', () async {
      expect(db.values.values.whereType<Commit>().length, 0);
      when(
        githubService.getReference(
          RepositorySlug(owner, repository),
          'heads/$branch',
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: 'refs/$branch', object: GitObject('', sha, '')),
        );
      });

      when(
        repositories.getCommit(RepositorySlug(owner, repository), sha),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(
          RepositoryCommit(
            sha: sha,
            author: User(login: username, avatarUrl: avatarUrl),
            commit: GitCommit(message: message),
          ),
        );
      });

      final createEvent = generateCreateBranchEvent(
        branch,
        '$owner/$repository',
      );
      await commitService.handleCreateGithubRequest(createEvent);

      expect(db.values.values.whereType<Commit>().length, 1);
      final commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, '$owner/$repository');
      expect(commit.message, message);
      expect(commit.key.id, '$owner/$repository/$branch/$sha');
      expect(commit.sha, sha);
      expect(commit.author, username);
      expect(commit.authorAvatarUrl, avatarUrl);
      expect(commit.branch, branch);

      expect(
        firestore,
        existsInStorage(fs.Commit.metadata, [
          isCommit
              .hasSha(sha)
              .hasRepositoryPath('$owner/$repository')
              .hasBranch(branch)
              .hasAuthor(username)
              .hasAvatar(avatarUrl)
              .hasMessage(message),
        ]),
      );
    });

    test('does not add commit to db if it exists in the datastore', () async {
      final existingCommit = generateCommit(
        1,
        sha: sha,
        branch: branch,
        owner: owner,
        repo: repository,
        timestamp: 0,
      );
      final datastoreCommit = <Commit>[existingCommit];
      await config.db.commit(inserts: datastoreCommit);
      expect(db.values.values.whereType<Commit>().length, 1);

      when(
        githubService.getReference(
          RepositorySlug(owner, repository),
          'heads/$branch',
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: 'refs/$branch', object: GitObject('', sha, '')),
        );
      });

      when(
        repositories.getCommit(RepositorySlug(owner, repository), sha),
      ).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(
          RepositoryCommit(
            sha: sha,
            author: User(
              createdAt: DateTime.parse(dateTimeAsString),
              login: username,
              avatarUrl: avatarUrl,
            ),
            commit: GitCommit(message: message),
          ),
        );
      });

      final createEvent = generateCreateBranchEvent(
        branch,
        '$owner/$repository',
      );
      await commitService.handleCreateGithubRequest(createEvent);

      expect(db.values.values.whereType<Commit>().length, 1);
      final commit = db.values.values.whereType<Commit>().single;
      expect(commit, existingCommit);

      expect(firestore, existsInStorage(fs.Commit.metadata, hasLength(1)));
    });
  });

  group('handlePushGithubRequest', () {
    test('adds commit to db if it does not exist in the datastore', () async {
      expect(db.values.values.whereType<Commit>().length, 0);

      final pushEvent = generatePushEvent(
        branch,
        owner,
        repository,
        message: message,
        sha: sha,
        avatarUrl: avatarUrl,
        username: username,
      );
      await commitService.handlePushGithubRequest(pushEvent);

      expect(db.values.values.whereType<Commit>().length, 1);
      final commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, '$owner/$repository');
      expect(commit.message, message);
      expect(commit.key.id, '$owner/$repository/$branch/$sha');
      expect(commit.sha, sha);
      expect(commit.author, username);
      expect(commit.authorAvatarUrl, avatarUrl);
      expect(commit.branch, branch);

      expect(
        firestore,
        existsInStorage(fs.Commit.metadata, [
          isCommit
              .hasSha(sha)
              .hasRepositoryPath('$owner/$repository')
              .hasBranch(branch)
              .hasAuthor(username)
              .hasAvatar(avatarUrl)
              .hasMessage(message),
        ]),
      );
    });

    test('does not add commit to db if it exists in the datastore', () async {
      final existingCommit = generateCommit(
        1,
        sha: sha,
        branch: branch,
        owner: owner,
        repo: repository,
        timestamp: 0,
      );
      final datastoreCommit = <Commit>[existingCommit];
      await config.db.commit(inserts: datastoreCommit);
      expect(db.values.values.whereType<Commit>().length, 1);

      final pushEvent = generatePushEvent(
        branch,
        owner,
        repository,
        message: message,
        sha: sha,
        avatarUrl: avatarUrl,
        username: username,
      );
      await commitService.handlePushGithubRequest(pushEvent);

      expect(db.values.values.whereType<Commit>().length, 1);
      final commit = db.values.values.whereType<Commit>().single;
      expect(commit, existingCommit);

      expect(firestore, existsInStorage(fs.Commit.metadata, hasLength(1)));
    });
  });
}
