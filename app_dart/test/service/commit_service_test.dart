// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as firestore;
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:github/hooks.dart';

import '../src/datastore/fake_datastore.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.mocks.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  late MockConfig config;
  late FakeDatastoreDB db;
  late CommitService commitService;
  late MockGithubService githubService;
  late MockRepositoriesService repositories;
  late MockGitHub github;
  late MockFirestoreService mockFirestoreService;
  const String owner = 'flutter';
  const String repository = 'flutter';
  const String branch = 'coolest-branch';
  const String sha = '1234';
  const String message = 'Adding null safety';
  const String avatarUrl = 'https://avatars.githubusercontent.com/u/fake-user-num';
  const String username = 'AwesomeGithubUser';
  const String dateTimeAsString = '2023-08-18T19:27:00Z';

  setUp(() {
    db = FakeDatastoreDB();
    github = MockGitHub();
    githubService = MockGithubService();
    mockFirestoreService = MockFirestoreService();
    when(githubService.github).thenReturn(github);
    repositories = MockRepositoriesService();
    when(github.repositories).thenReturn(repositories);
    config = MockConfig();
    commitService = CommitService(config: config);

    when(config.createDefaultGitHubService()).thenAnswer((_) async => githubService);
    when(config.createFirestoreService()).thenAnswer((_) async => mockFirestoreService);
    when(config.db).thenReturn(db);
  });

  group('handleCreateGithubRequest', () {
    test('adds commit to db if it does not exist in the datastore', () async {
      expect(db.values.values.whereType<Commit>().length, 0);
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      when(githubService.getReference(RepositorySlug(owner, repository), 'heads/$branch'))
          .thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: 'refs/$branch', object: GitObject('', sha, '')),
        );
      });

      when(repositories.getCommit(RepositorySlug(owner, repository), sha)).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(
          RepositoryCommit(
            sha: sha,
            author: User(
              login: username,
              avatarUrl: avatarUrl,
            ),
            commit: GitCommit(message: message),
          ),
        );
      });

      final CreateEvent createEvent = generateCreateBranchEvent(branch, '$owner/$repository');
      await commitService.handleCreateGithubRequest(createEvent);

      expect(db.values.values.whereType<Commit>().length, 1);
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, '$owner/$repository');
      expect(commit.message, message);
      expect(commit.key.id, '$owner/$repository/$branch/$sha');
      expect(commit.sha, sha);
      expect(commit.author, username);
      expect(commit.authorAvatarUrl, avatarUrl);
      expect(commit.branch, branch);

      final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
      expect(batchWriteRequest.writes!.length, 1);
      final Document insertedCommitDocument = batchWriteRequest.writes![0].update!;
      expect(insertedCommitDocument.name, '$kDatabase/documents/$kCommitCollectionId/$sha');
    });

    test('does not add commit to db if it exists in the datastore', () async {
      final Commit existingCommit = generateCommit(
        1,
        sha: sha,
        branch: branch,
        owner: owner,
        repo: repository,
        timestamp: 0,
      );
      final List<Commit> datastoreCommit = <Commit>[existingCommit];
      await config.db.commit(inserts: datastoreCommit);
      expect(db.values.values.whereType<Commit>().length, 1);

      when(githubService.getReference(RepositorySlug(owner, repository), 'heads/$branch'))
          .thenAnswer((Invocation invocation) {
        return Future<GitReference>.value(
          GitReference(ref: 'refs/$branch', object: GitObject('', sha, '')),
        );
      });

      when(repositories.getCommit(RepositorySlug(owner, repository), sha)).thenAnswer((Invocation invocation) {
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

      final CreateEvent createEvent = generateCreateBranchEvent(branch, '$owner/$repository');
      await commitService.handleCreateGithubRequest(createEvent);

      expect(db.values.values.whereType<Commit>().length, 1);
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit, existingCommit);
    });
  });

  group('handlePushGithubRequest', () {
    test('adds commit to db if it does not exist in the datastore', () async {
      expect(db.values.values.whereType<Commit>().length, 0);

      final Map<String, dynamic> pushEvent = generatePushEvent(
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
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, '$owner/$repository');
      expect(commit.message, message);
      expect(commit.key.id, '$owner/$repository/$branch/$sha');
      expect(commit.sha, sha);
      expect(commit.author, username);
      expect(commit.authorAvatarUrl, avatarUrl);
      expect(commit.branch, branch);
    });

    test('does not add commit to db if it exists in the datastore', () async {
      final Commit existingCommit = generateCommit(
        1,
        sha: sha,
        branch: branch,
        owner: owner,
        repo: repository,
        timestamp: 0,
      );
      final List<Commit> datastoreCommit = <Commit>[existingCommit];
      await config.db.commit(inserts: datastoreCommit);
      expect(db.values.values.whereType<Commit>().length, 1);

      final Map<String, dynamic> pushEvent = generatePushEvent(
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
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit, existingCommit);
    });
  });
}
