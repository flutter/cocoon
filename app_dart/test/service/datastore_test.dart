// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/datastore.dart' as gcloud_datastore;
import 'package:gcloud/db.dart';
import 'package:grpc/grpc.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/utilities/entity_generators.dart';

class Counter {
  int count = 0;
  void increase() {
    count = count + 1;
  }

  int value() {
    return count;
  }
}

void main() {
  group('Datastore', () {
    late FakeConfig config;
    late FakeDatastoreDB db;
    late DatastoreService datastoreService;
    late Commit commit;

    setUp(() {
      db = FakeDatastoreDB();
      config = FakeConfig(dbValue: db);
      datastoreService = DatastoreService(config.db, 5);
      commit = Commit(
        key: config.db.emptyKey.append(Commit, id: 'abc_master'),
        sha: 'abc_master',
        repository: Config.flutterSlug.fullName,
        branch: 'master',
      );
    });

    group('DatasourceService', () {
      setUp(() {});

      test('defaultProvider returns a DatasourceService object', () async {
        expect(DatastoreService.defaultProvider(config.db), isA<DatastoreService>());
      });

      test('queryRecentCommits', () async {
        for (String branch in <String>['master', 'release']) {
          final Commit commit = Commit(
            key: config.db.emptyKey.append(Commit, id: 'abc_$branch'),
            repository: Config.flutterSlug.fullName,
            sha: 'abc_$branch',
            branch: branch,
          );
          config.db.values[commit.key] = commit;
        }
        // Defaults to master
        List<Commit> commits = await datastoreService.queryRecentCommits(slug: Config.flutterSlug).toList();
        expect(commits, hasLength(1));
        expect(commits[0].branch, equals('master'));
        // Explicit branch
        commits = await datastoreService.queryRecentCommits(branch: 'release', slug: Config.flutterSlug).toList();
        expect(commits, hasLength(1));
        expect(commits[0].branch, equals('release'));
      });

      test('queryRecentCommits with slug', () async {
        for (String repo in <String>['flutter', 'engine']) {
          final Commit commit = Commit(
            key: config.db.emptyKey.append(Commit, id: 'flutter/$repo/main/abc'),
            repository: 'flutter/$repo',
            sha: 'abc',
            branch: 'main',
          );
          config.db.values[commit.key] = commit;
        }
        // Only retrieves flutter/flutter
        List<Commit> commits =
            await datastoreService.queryRecentCommits(slug: Config.flutterSlug, branch: 'main').toList();
        expect(commits, hasLength(1));
        expect(commits.single.repository, equals('flutter/flutter'));
        // Only retrieves flutter/engine
        commits = await datastoreService.queryRecentCommits(branch: 'main', slug: Config.engineSlug).toList();
        expect(commits, hasLength(1));
        expect(commits.single.repository, equals('flutter/engine'));
      });
    });

    test('queryRecentCommits with repo default branch', () async {
      for (String branch in <String>['master', 'main']) {
        final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'abc_$branch'),
          repository: Config.engineSlug.fullName,
          sha: 'abc_$branch',
          branch: branch,
        );
        config.db.values[commit.key] = commit;
      }
      // Pull from main, not master
      final List<Commit> commits = await datastoreService.queryRecentCommits(slug: Config.engineSlug).toList();
      expect(commits, hasLength(1));
      expect(commits[0].branch, equals('main'));
    });

    test('queryRecentTasks returns all tasks', () async {
      const String branch = 'main';
      final Commit commit = Commit(
        key: config.db.emptyKey.append(Commit, id: 'abc_$branch'),
        repository: Config.engineSlug.fullName,
        sha: 'abc_$branch',
        branch: branch,
      );
      const int taskNumber = 2;
      for (int i = 0; i < taskNumber; i++) {
        final Task task = generateTask(
          i,
          parent: commit,
        );
        config.db.values[task.key] = task;
      }

      config.db.values[commit.key] = commit;
      final List<FullTask> datastoreTasks = await datastoreService
          .queryRecentTasks(
            slug: Config.engineSlug,
          )
          .toList();
      expect(datastoreTasks, hasLength(taskNumber));
    });

    test('Shard', () async {
      // default maxEntityGroups = 5
      List<List<Model<dynamic>>> shards = await datastoreService.shard(generateCommits(6));
      expect(shards, hasLength(2));
      expect(shards[0], hasLength(5));
      expect(shards[1], hasLength(1));
      // maxEntitygroups = 2
      datastoreService = DatastoreService(config.db, 2);
      shards = await datastoreService.shard(generateCommits(3));
      expect(shards, hasLength(2));
      expect(shards[0], hasLength(2));
      expect(shards[1], hasLength(1));
      // maxEntityGroups = 1
      datastoreService = DatastoreService(config.db, 1);
      shards = await datastoreService.shard(generateCommits(3));
      expect(shards, hasLength(3));
      expect(shards[0], hasLength(1));
      expect(shards[1], hasLength(1));
      expect(shards[2], hasLength(1));
    });

    test('Insert', () async {
      await datastoreService.insert(<Commit>[commit]);
      expect(config.db.values[commit.key], equals(commit));
    });

    test('LookupByKey', () async {
      config.db.values[commit.key] = commit;
      final List<Commit?> commits = await datastoreService.lookupByKey(<Key<dynamic>>[commit.key]);
      expect(commits, hasLength(1));
      expect(commits[0], equals(commit));
    });

    test('LookupByValue', () async {
      config.db.values[commit.key] = commit;
      final Commit expected = await datastoreService.lookupByValue(commit.key);
      expect(expected, equals(commit));
    });

    test('WithTransaction', () async {
      final String? expected = await datastoreService.withTransaction((Transaction transaction) async {
        transaction.queueMutations(inserts: <Commit>[commit]);
        await transaction.commit();
        return 'success';
      });
      expect(expected, equals('success'));
      expect(config.db.values[commit.key], equals(commit));
    });
  });

  group('RunTransactionWithRetry', () {
    late RetryOptions retryOptions;

    setUp(() {
      retryOptions = const RetryOptions(
        delayFactor: Duration(milliseconds: 1),
        maxDelay: Duration(milliseconds: 2),
        maxAttempts: 2,
      );
    });

    test('retriesOnGrpcError', () async {
      final Counter counter = Counter();
      try {
        await runTransactionWithRetries(
          () async {
            counter.increase();
            throw GrpcError.aborted();
          },
          retryOptions: retryOptions,
        );
      } catch (e) {
        expect(e, isA<GrpcError>());
      }
      expect(counter.value(), greaterThan(1));
    });
    test('retriesTransactionAbortedError', () async {
      final Counter counter = Counter();
      try {
        await runTransactionWithRetries(
          () async {
            counter.increase();
            throw gcloud_datastore.TransactionAbortedError();
          },
          retryOptions: retryOptions,
        );
      } catch (e) {
        expect(e, isA<gcloud_datastore.TransactionAbortedError>());
      }
      expect(counter.value(), greaterThan(1));
    });
    test('DoesNotRetryOnSuccess', () async {
      final Counter counter = Counter();
      await runTransactionWithRetries(
        () async {
          counter.increase();
        },
        retryOptions: retryOptions,
      );
      expect(counter.value(), equals(1));
    });
  });
}

/// Helper function to generate fake commits
List<Commit> generateCommits(int i) {
  return List<Commit>.generate(i, (int i) => Commit(repository: 'flutter/flutter', sha: '$i'));
}
