// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/schedule_postsubmits_for_commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:gcloud/db.dart';
import 'package:logging/logging.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/api_request_handler_tester.dart';
import '../../src/request_handling/fake_authentication.dart';

void main() {
  late ApiRequestHandlerTester tester;
  late FakeAuthenticationProvider authenticationProvider;
  late SchedulePostsubmitsForCommit requestHandler;
  late FutureOr<bool> Function(Commit) addCommit;
  late Scheduler scheduler;
  late DatastoreDB datastoreDB;
  late List<String> logs;

  setUp(() {
    addCommit = (_) => throw UnimplementedError();
    scheduler = _FakeAddCommitScheduler(addCommit: (commit) => addCommit(commit));
    datastoreDB = _FakeEmptyKeyDatastoreDB();
    authenticationProvider = FakeAuthenticationProvider();
    requestHandler = SchedulePostsubmitsForCommit(
      config: FakeConfig(),
      authenticationProvider: authenticationProvider,
      scheduler: scheduler,
      datastore: datastoreDB,
    );
    tester = ApiRequestHandlerTester();
    logs = [];
    log = Logger.detached('logger');
    log.onRecord.listen((record) {
      logs.add(record.message);
    });
  });

  tearDown(() {
    printOnFailure(logs.join());
  });

  test('should fail if missing POST data', () async {
    await expectLater(
      tester.post(requestHandler),
      throwsA(
        isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          contains('Invalid POST body'),
        ),
      ),
    );
  });

  test('should fail if not targeting flutter/flutter', () async {
    tester.requestData = {
      'repo': 'cocoon',
      'branch': 'flutter-release',
      'commit': 'abc123',
    };
    await expectLater(
      tester.post(requestHandler),
      throwsA(
        isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          matches(RegExp('Only non-master.*on the flutter.*can use.*SchedulePostsubmitsForCommit')),
        ),
      ),
    );
  });

  test('should fail if targeting master branch', () async {
    tester.requestData = {
      'repo': 'flutter',
      'branch': 'master',
      'commit': 'abc123',
    };
    await expectLater(
      tester.post(requestHandler),
      throwsA(
        isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          matches(RegExp('Only non-master.*on the flutter.*can use.*SchedulePostsubmitsForCommit')),
        ),
      ),
    );
  });

  test('returns a 500 error if scheduler.addCommit fails', () async {
    tester.requestData = {
      'repo': 'flutter',
      'branch': 'flutter-release',
      'commit': 'abc123',
    };
    addCommit = (_) => false;

    await tester.post(requestHandler);
    expect(tester.response.statusCode, 500);
  });

  test('returns an empty 200 if scheduler.addCommit succeeds', () async {
    tester.requestData = {
      'repo': 'flutter',
      'branch': 'flutter-release',
      'commit': 'abc123',
    };
    addCommit = (_) => true;

    await expectLater(tester.post(requestHandler), completion(Body.empty));
  });
}

/// A fake [Scheduler] that delegates the implementation of [addCommit].
///
/// All other methods throw.
final class _FakeAddCommitScheduler extends Fake implements Scheduler {
  _FakeAddCommitScheduler({
    required FutureOr<bool> Function(Commit) addCommit,
  }) : _addCommit = addCommit;
  final FutureOr<bool> Function(Commit) _addCommit;

  @override
  Future<bool> addCommit(Commit commit) async => await _addCommit(commit);
}

/// A fake [DatastoreDB] that provides [emptyKey].
///
/// All other methods throw.
final class _FakeEmptyKeyDatastoreDB extends Fake implements DatastoreDB {
  static final _defaultPartition = Partition(null);

  @override
  Key<Object?> get emptyKey => _defaultPartition.emptyKey;
}
