// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/build_status_snapshot.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/request_handlers/update_discord_status.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart'
    hide BuildStatus;
import 'package:cocoon_service/src/service/discord_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/model/firestore_matcher.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_firestore_service.dart'
    show FakeFirestoreService, existsInStorage;
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late UpdateDiscordStatus handler;
  late FakeFirestoreService firestore;
  late MockDiscordService discord;

  Future<T> decodeHandlerBody<T>() async {
    tester.request!.uri = tester.request!.uri.replace(query: 'repo=flutter');
    final body = await tester.get(handler);
    return await utf8.decoder
            .bind(body.serialize() as Stream<List<int>>)
            .transform(json.decoder)
            .single
        as T;
  }

  final alwaysTime = DateTime(2025, 4, 9, 12, 00);

  setUp(() {
    discord = MockDiscordService();
    when(
      discord.postTreeStatusMessage(any),
    ).thenAnswer((_) async => DiscordStatus.ok);

    firestore = FakeFirestoreService();

    tester = RequestHandlerTester();
    handler = UpdateDiscordStatus(
      config: FakeConfig(),
      discord: discord,
      buildStatusService: BuildStatusService(firestore: firestore),
      firestore: firestore,
      now: () => alwaysTime,
    );
  });

  test('creates an initial doc when the first status is a failure', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(1, status: Task.statusFailed, commitSha: '1'),
    );

    await decodeHandlerBody<Map<String, Object?>>();

    expect(
      firestore,
      existsInStorage(BuildStatusSnapshot.metadata, [
        isBuildStatusSnapshot.hasStatus(BuildStatus.failure),
      ]),
    );

    // Verify we actually posted it
    final [message] =
        verify(discord.postTreeStatusMessage(captureAny)).captured;
    expect(message, contains('flutter/flutter is now :red_circle:!'));
  });

  test('does not post on unchanged value', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(1, status: Task.statusSucceeded, commitSha: '1'),
    );

    await firestore.createDocument(
      BuildStatusSnapshot(
        createdOn: alwaysTime.toUtc(),
        status: BuildStatus.success,
        failingTasks: [],
      ),
      collectionId: BuildStatusSnapshot.metadata.collectionId,
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we never wrote a document
    expect(
      firestore,
      existsInStorage(BuildStatusSnapshot.metadata, hasLength(1)),
    );

    // Verify we never posted it
    verifyNever(discord.postTreeStatusMessage(any));
  });

  test('posts on success -> failed', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(
        1,
        status: Task.statusFailed,
        commitSha: '1',
        name: 'Linux foo',
      ),
    );
    await firestore.createDocument(
      BuildStatusSnapshot(
        createdOn: alwaysTime.toUtc(),
        status: BuildStatus.success,
        failingTasks: [],
      ),
      collectionId: BuildStatusSnapshot.metadata.collectionId,
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we wrote the status
    expect(
      firestore,
      existsInStorage(BuildStatusSnapshot.metadata, [
        isBuildStatusSnapshot.hasStatus(BuildStatus.success),
        isBuildStatusSnapshot.hasStatus(BuildStatus.failure),
      ]),
    );

    // Verify we actually posted it
    final [String message] =
        verify(discord.postTreeStatusMessage(captureAny)).captured;
    expect(
      message,
      stringContainsInOrder([
        'flutter/flutter is now :red_circle:',
        'Now failing',
        'Linux foo',
      ]),
    );
  });

  test('posts on failed -> success', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(
        1,
        status: Task.statusSucceeded,
        commitSha: '1',
        name: 'Linux foo',
        created: alwaysTime,
      ),
    );
    await firestore.createDocument(
      BuildStatusSnapshot(
        createdOn: alwaysTime.subtract(const Duration(hours: 1)),
        status: BuildStatus.failure,
        failingTasks: ['Linux foo'],
      ),
      collectionId: BuildStatusSnapshot.metadata.collectionId,
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we wrote the status
    expect(
      firestore,
      existsInStorage(BuildStatusSnapshot.metadata, [
        isBuildStatusSnapshot.hasStatus(BuildStatus.failure),
        isBuildStatusSnapshot.hasStatus(BuildStatus.success),
      ]),
    );

    // Verify we actually posted it
    final [String message] =
        verify(discord.postTreeStatusMessage(captureAny)).captured;
    expect(
      message,
      stringContainsInOrder([
        'flutter/flutter is now :green_circle:',
        'It took 60 minutes to become green',
        'Now passing',
        'Linux foo',
      ]),
    );
  });

  test('posts on failed -> failed (tasks changed)', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(
        1,
        status: Task.statusFailed,
        commitSha: '1',
        name: 'Linux foo',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        1,
        status: Task.statusFailed,
        commitSha: '1',
        name: 'Mac bar',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        1,
        status: Task.statusSucceeded,
        commitSha: '1',
        name: 'Windows baz',
      ),
    );

    await firestore.createDocument(
      BuildStatusSnapshot(
        createdOn: alwaysTime.toUtc(),
        status: BuildStatus.failure,
        failingTasks: ['Linux foo', 'Windows baz'],
      ),
      collectionId: BuildStatusSnapshot.metadata.collectionId,
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we wrote the status
    expect(
      firestore,
      existsInStorage(BuildStatusSnapshot.metadata, [
        isBuildStatusSnapshot.hasStatus(BuildStatus.failure),
        isBuildStatusSnapshot.hasStatus(BuildStatus.failure),
      ]),
    );

    // Verify we actually posted it
    final [String message] =
        verify(discord.postTreeStatusMessage(captureAny)).captured;
    expect(
      message,
      stringContainsInOrder([
        'flutter/flutter is still :red_circle:',
        'Now failing',
        'Mac bar',
        'Still failing',
        'Linux foo',
        'Now passing',
        'Windows baz',
      ]),
    );
  });

  test('limits size of the message sent to discord', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'a' * 2000,
        status: Task.statusFailed,
        commitSha: '1',
      ),
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we actually posted it
    final [String message] =
        verify(discord.postTreeStatusMessage(captureAny)).captured;

    expect(
      message,
      stringContainsInOrder([
        'flutter/flutter is now :red_circle:!',
        ':cry: 1 tasks are failing',
      ]),
    );
  });
}
