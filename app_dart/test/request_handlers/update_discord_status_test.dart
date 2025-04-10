// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/request_handlers/update_discord_status.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/discord_service.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late UpdateDiscordStatus handler;
  late MockFirestoreService mockFirestoreService;
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

  final createdDocuments = <Document>[];
  final queryDocuments = <List<Document>>[];
  final alwaysTime = DateTime(2025, 4, 9, 12, 00);

  setUp(() {
    createdDocuments.clear();
    queryDocuments.clear();

    discord = MockDiscordService();
    when(
      discord.postTreeStatusMessage(any),
    ).thenAnswer((_) async => DiscordStatus.ok);

    mockFirestoreService = MockFirestoreService();
    when(
      mockFirestoreService.query(
        any,
        any,
        limit: anyNamed('limit'),
        orderMap: anyNamed('orderMap'),
        compositeFilterOp: anyNamed('compositeFilterOp'),
      ),
    ).thenAnswer(
      (_) async =>
          queryDocuments.isEmpty ? <Document>[] : queryDocuments.removeAt(0),
    );
    when(
      mockFirestoreService.createDocument(
        any,
        collectionId: 'last_build_status',
      ),
    ).thenAnswer((invocation) async {
      createdDocuments.add(invocation.positionalArguments.first as Document);
      return createdDocuments.last;
    });

    final config = FakeConfig();
    config.firestoreService = mockFirestoreService;

    tester = RequestHandlerTester();
    handler = UpdateDiscordStatus(
      config: config,
      discord: discord,
      buildStatusService: BuildStatusService(config),
      now: () => alwaysTime,
    );
  });

  test('posts when status is missing in firestore', () async {
    final commit = generateFirestoreCommit(1);
    when(
      mockFirestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        branch: anyNamed('branch'),
        limit: anyNamed('limit'),
        timestamp: anyNamed('timestamp'),
      ),
    ).thenAnswer((_) async => [commit]);

    final task = generateFirestoreTask(1, status: Task.statusSucceeded);
    when(
      mockFirestoreService.queryCommitTasks(commit.sha),
    ).thenAnswer((_) async => [task]);

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we wrote the status
    expect(createdDocuments, hasLength(1));
    print(createdDocuments.first.toJson());
    verify(
      mockFirestoreService.createDocument(
        any,
        collectionId: 'last_build_status',
      ),
    ).called(1);
    final doc = createdDocuments.first;
    expect(
      doc.fields!['status']!.stringValue,
      'flutter/flutter is :green_circle:!',
    );
    expect(
      doc.fields!['createTimestamp']!.timestampValue,
      alwaysTime.toIso8601String(),
    );

    // Verify we actually posted it
    verify(
      discord.postTreeStatusMessage('flutter/flutter is :green_circle:!'),
    ).called(1);
  });

  test('does not post on unchanged value', () async {
    queryDocuments.add([
      Document(
        fields: {
          'status': Value(stringValue: 'flutter/flutter is :green_circle:!'),
          'createTimestamp': Value(
            timestampValue: alwaysTime.toIso8601String(),
          ),
        },
      ),
    ]);
    final commit = generateFirestoreCommit(1);
    when(
      mockFirestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        branch: anyNamed('branch'),
        limit: anyNamed('limit'),
        timestamp: anyNamed('timestamp'),
      ),
    ).thenAnswer((_) async => [commit]);

    final task = generateFirestoreTask(1, status: Task.statusSucceeded);
    when(
      mockFirestoreService.queryCommitTasks(commit.sha),
    ).thenAnswer((_) async => [task]);

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we never posted it
    verifyNever(discord.postTreeStatusMessage(any));
  });

  test('posts on changed value', () async {
    queryDocuments.add([
      Document(
        fields: {
          'status': Value(stringValue: 'flutter/flutter is :red_circle:!'),
          'createTimestamp': Value(
            timestampValue: alwaysTime.toIso8601String(),
          ),
        },
      ),
    ]);
    final commit = generateFirestoreCommit(1);
    when(
      mockFirestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        branch: anyNamed('branch'),
        limit: anyNamed('limit'),
        timestamp: anyNamed('timestamp'),
      ),
    ).thenAnswer((_) async => [commit]);

    final task = generateFirestoreTask(1, status: Task.statusSucceeded);
    when(
      mockFirestoreService.queryCommitTasks(commit.sha),
    ).thenAnswer((_) async => [task]);

    await decodeHandlerBody<Map<String, Object?>>();

    expect(createdDocuments, hasLength(1));
    expect(
      createdDocuments.first.fields!['status']!.stringValue,
      'flutter/flutter is :green_circle:!',
    );

    // Verify we actually posted it
    verify(
      discord.postTreeStatusMessage('flutter/flutter is :green_circle:!'),
    ).called(1);
  });

  test('limits size of the message sent to discord', () async {
    queryDocuments.add([
      Document(
        fields: {
          'status': Value(stringValue: 'flutter/flutter is :red_circle:!'),
          'createTimestamp': Value(
            timestampValue: alwaysTime.toIso8601String(),
          ),
        },
      ),
    ]);
    final commit = generateFirestoreCommit(1);
    when(
      mockFirestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        branch: anyNamed('branch'),
        limit: anyNamed('limit'),
        timestamp: anyNamed('timestamp'),
      ),
    ).thenAnswer((_) async => [commit]);

    final task = generateFirestoreTask(
      1,
      name: 'a' * 2000,
      status: Task.statusFailed,
    );
    when(
      mockFirestoreService.queryCommitTasks(commit.sha),
    ).thenAnswer((_) async => [task]);

    await decodeHandlerBody<Map<String, Object?>>();

    expect(createdDocuments, hasLength(1));
    expect(
      createdDocuments.first.fields!['status']!.stringValue,
      'flutter/flutter is :red_circle:! Failing tasks: ${'a' * 2000}',
    );

    // Verify we actually posted it
    final captured = verify(discord.postTreeStatusMessage(captureAny)).captured;
    expect(captured, hasLength(1));
    expect(
      captured.first,
      startsWith('flutter/flutter is :red_circle:! Failing tasks: aaaaaaaaa'),
    );
    expect(
      captured.first,
      endsWith('aaaaa... things appear to be very broken right now. :cry:'),
    );
  });
}
