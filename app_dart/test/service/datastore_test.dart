// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/datastore.dart' as gcloud_datastore;
import 'package:gcloud/db.dart';
import 'package:test/test.dart';
import 'package:grpc/grpc.dart';
import 'package:retry/retry.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';

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
    FakeConfig config;
    FakeDatastoreDB db;
    DatastoreService datastoreService;
    Commit commit;

    setUp(() {
      db = FakeDatastoreDB();
      config = FakeConfig(dbValue: db);
      datastoreService = DatastoreService(config.db, 5);
      commit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'abc_master'),
          sha: 'abc_master',
          branch: 'master');
    });

    group('DatasourceService', () {
      setUp(() {});

      test('defaultProvider returns a DatasourceService object', () async {
        expect(DatastoreService.defaultProvider(config.db),
            isA<DatastoreService>());
      });

      test('QueryRecentCommits', () async {
        for (String branch in <String>['master', 'release']) {
          final Commit commit = Commit(
              key: config.db.emptyKey.append(Commit, id: 'abc_$branch'),
              sha: 'abc_$branch',
              branch: branch);
          config.db.values[commit.key] = commit;
        }
        // Defaults to master
        List<Commit> commits =
            await datastoreService.queryRecentCommits().toList();
        expect(commits, hasLength(1));
        expect(commits[0].branch, equals('master'));
        // Explicit branch
        commits = await datastoreService
            .queryRecentCommits(branch: 'release')
            .toList();
        expect(commits, hasLength(1));
        expect(commits[0].branch, equals('release'));
      });
      test('QueryRecentCommitsNoBranch', () async {
        // Empty results
        List<Commit> commits =
            await datastoreService.queryRecentCommits().toList();
        expect(commits, isEmpty);
        for (String branch in <String>['master', 'release']) {
          final Commit commit = Commit(
              key: config.db.emptyKey.append(Commit, id: 'abc_$branch'),
              sha: 'abc_$branch',
              branch: branch);
          config.db.values[commit.key] = commit;
        }
        // Results from two branches
        commits = await datastoreService.queryRecentCommitsNoBranch().toList();
        expect(commits, hasLength(2));
      });

      test('QueryRecentTasksNoBranch - release branch', () async {
        final Commit commit = Commit(
            key: config.db.emptyKey.append(Commit, id: 'abc'),
            branch: 'release');
        config.db.values[commit.key] = commit;
        final Task task = Task(
            key: commit.key.append(Task, id: 123),
            commitKey: commit.key,
            attempts: 1,
            status: Task.statusInProgress,
            startTimestamp: DateTime.now().millisecondsSinceEpoch);
        db.values[task.key] = task;
        final List<FullTask> fullTasks =
            await datastoreService.queryRecentTasksNoBranch().toList();
        expect(fullTasks, hasLength(1));
        expect(fullTasks[0].commit.branch, 'release');
        expect(fullTasks[0].task.id, 123);
      });
    });

    test('Shard', () async {
      // default maxEntityGroups = 5
      List<List<Model>> shards = await datastoreService.shard(
          <Commit>[Commit(), Commit(), Commit(), Commit(), Commit(), Commit()]);
      expect(shards, hasLength(2));
      expect(shards[0], hasLength(5));
      expect(shards[1], hasLength(1));
      // maxEntigroups = 2
      datastoreService = DatastoreService(config.db, 2);
      shards =
          await datastoreService.shard(<Commit>[Commit(), Commit(), Commit()]);
      expect(shards, hasLength(2));
      expect(shards[0], hasLength(2));
      expect(shards[1], hasLength(1));
      // maxEntityGroups = 1
      datastoreService = DatastoreService(config.db, 1);
      shards =
          await datastoreService.shard(<Commit>[Commit(), Commit(), Commit()]);
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
      final List<Commit> commits =
          await datastoreService.lookupByKey(<Key>[commit.key]);
      expect(commits, hasLength(1));
      expect(commits[0], equals(commit));
    });

    test('LookupByValue', () async {
      config.db.values[commit.key] = commit;
      final Commit expected = await datastoreService.lookupByValue(commit.key);
      expect(expected, equals(commit));
    });

    test('WithTransaction', () async {
      final String expected = await datastoreService
          .withTransaction((Transaction transaction) async {
        transaction.queueMutations(inserts: <Commit>[commit]);
        await transaction.commit();
        return 'success';
      });
      expect(expected, equals('success'));
      expect(config.db.values[commit.key], equals(commit));
    });
  });

  group('RunTransactionWithRetry', () {
    RetryOptions retryOptions;

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
        await runTransactionWithRetries(() async {
          counter.increase();
          throw GrpcError.aborted();
        }, retryOptions: retryOptions);
      } catch (e) {
        expect(e, isA<GrpcError>());
      }
      expect(counter.value(), greaterThan(1));
    });
    test('retriesTransactionAbortedError', () async {
      final Counter counter = Counter();
      try {
        await runTransactionWithRetries(() async {
          counter.increase();
          throw gcloud_datastore.TransactionAbortedError();
        }, retryOptions: retryOptions);
      } catch (e) {
        expect(e, isA<gcloud_datastore.TransactionAbortedError>());
      }
      expect(counter.value(), greaterThan(1));
    });
    test('DoesNotRetryOnSuccess', () async {
      final Counter counter = Counter();
      await runTransactionWithRetries(() async {
        counter.increase();
      }, retryOptions: retryOptions);
      expect(counter.value(), equals(1));
    });
  });
}
