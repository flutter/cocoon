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
import '../src/service/fake_firestore_service.dart' show FakeFirestoreService;
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

    final config = FakeConfig();
    config.firestoreService = firestore;

    tester = RequestHandlerTester();
    handler = UpdateDiscordStatus(
      config: config,
      discord: discord,
      buildStatusService: BuildStatusService(config),
      now: () => alwaysTime,
    );
  });

  test('posts when status is missing in firestore', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(1, status: Task.statusSucceeded, commitSha: '1'),
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we wrote the status
    final lastBuildStatuses = [
      for (var doc in firestore.documents)
        if (doc.name!.startsWith(
          'projects/flutter-dashboard/databases/cocoon/documents/last_build_status/',
        ))
          doc,
    ];
    expect(lastBuildStatuses, hasLength(1));
    final doc = lastBuildStatuses.first;
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
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(1, status: Task.statusSucceeded, commitSha: '1'),
    );
    firestore.putDocument(
      Document(
        name:
            'projects/flutter-dashboard/databases/cocoon/documents/last_build_status/fu',
        fields: {
          'status': Value(stringValue: 'flutter/flutter is :green_circle:!'),
          'createTimestamp': Value(
            timestampValue:
                alwaysTime
                    .subtract(const Duration(seconds: 1))
                    .toIso8601String(),
          ),
        },
      ),
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we never wrote another
    final lastBuildStatuses = [
      for (var doc in firestore.documents)
        if (doc.name!.startsWith(
          'projects/flutter-dashboard/databases/cocoon/documents/last_build_status/',
        ))
          doc,
    ];
    expect(lastBuildStatuses, hasLength(1));

    // Verify we never posted it
    verifyNever(discord.postTreeStatusMessage(any));
  });

  test('posts on changed value', () async {
    firestore.putDocument(generateFirestoreCommit(1));
    firestore.putDocument(
      generateFirestoreTask(1, status: Task.statusSucceeded, commitSha: '1'),
    );
    firestore.putDocument(
      Document(
        name:
            'projects/flutter-dashboard/databases/cocoon/documents/last_build_status/fu',
        fields: {
          'status': Value(stringValue: 'flutter/flutter is :red_circle:!'),
          'createTimestamp': Value(
            timestampValue:
                alwaysTime
                    .subtract(const Duration(seconds: 1))
                    .toIso8601String(),
          ),
        },
      ),
    );

    await decodeHandlerBody<Map<String, Object?>>();

    // Verify we wrote the status
    final lastBuildStatuses = [
      for (var doc in firestore.documents)
        if (doc.name!.startsWith(
          'projects/flutter-dashboard/databases/cocoon/documents/last_build_status/',
        ))
          doc,
    ];
    expect(lastBuildStatuses, hasLength(2));

    final doc = lastBuildStatuses.firstWhere(
      (doc) => !doc.name!.endsWith('/fu'),
    );
    expect(
      doc.fields!['status']!.stringValue,
      'flutter/flutter is :green_circle:!',
    );

    // Verify we actually posted it
    verify(
      discord.postTreeStatusMessage('flutter/flutter is :green_circle:!'),
    ).called(1);
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

    firestore.putDocument(
      Document(
        name:
            'projects/flutter-dashboard/databases/cocoon/documents/last_build_status/fu',
        fields: {
          'status': Value(stringValue: 'flutter/flutter is :red_circle:!'),
          'createTimestamp': Value(
            timestampValue:
                alwaysTime
                    .subtract(const Duration(seconds: 1))
                    .toIso8601String(),
          ),
        },
      ),
    );

    await decodeHandlerBody<Map<String, Object?>>();

    final lastStatus = firestore.documents.firstWhere(
      (doc) =>
          doc.name!.startsWith(
            'projects/flutter-dashboard/databases/cocoon/documents/last_build_status/',
          ) &&
          !doc.name!.endsWith('/fu'),
    );

    expect(
      lastStatus.fields!['status']!.stringValue,
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
