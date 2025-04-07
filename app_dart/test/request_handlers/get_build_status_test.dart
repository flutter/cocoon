// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late GetBuildStatus handler;
  late MockFirestoreService mockFirestoreService;
  late MockClient httpClient;

  Future<T> decodeHandlerBody<T>() async {
    final body = await tester.get(handler);
    return await utf8.decoder
            .bind(body.serialize() as Stream<List<int>>)
            .transform(json.decoder)
            .single
        as T;
  }

  final requests = <Request>[];
  final responses = <Response>[];
  final createdDocuments = <Document>[];
  final queryDocuments = <List<Document>>[];
  final alwaysTime = DateTime(2025, 4, 9, 12, 00);

  setUp(() {
    requests.clear();
    responses.clear();
    createdDocuments.clear();
    queryDocuments.clear();

    responses.add(Response('', 200));
    httpClient = MockClient((request) async {
      requests.add(request);
      return responses.removeAt(0);
    });

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
    handler = GetBuildStatus(
      config: config,
      buildStatusService: BuildStatusService(config),
      httpClientProvider: () => httpClient,
      now: () => alwaysTime,
    );
  });

  test('passing status', () async {
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

    final response = await decodeHandlerBody<Map<String, Object?>>();
    expect(response, {'buildStatus': 'success', 'failingTasks': isEmpty});
  });

  test('failing status', () async {
    final commit = generateFirestoreCommit(1);
    when(
      mockFirestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        branch: anyNamed('branch'),
        limit: anyNamed('limit'),
        timestamp: anyNamed('timestamp'),
      ),
    ).thenAnswer((_) async => [commit]);

    final taskPass = generateFirestoreTask(1, status: Task.statusSucceeded);
    final taskFail = generateFirestoreTask(2, status: Task.statusFailed);
    when(
      mockFirestoreService.queryCommitTasks(commit.sha),
    ).thenAnswer((_) async => [taskPass, taskFail]);

    final response = await decodeHandlerBody<Map<String, Object?>>();
    expect(response, {
      'buildStatus': 'failure',
      'failingTasks': [taskFail.taskName],
    });
  });

  group('discordbot', () {
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
      expect(requests, hasLength(1));
      final request = requests.first;
      expect(request.body, '{"content":"flutter/flutter is :green_circle:!"}');
      expect(request.headers, contains('Content-Type'));
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse(await FakeConfig().discordTreeStatusWebhookUrl),
      );

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
      expect(requests, isEmpty);
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
      expect(requests, hasLength(1));
      expect(
        requests.first.body,
        '{"content":"flutter/flutter is :green_circle:!"}',
      );
      expect(createdDocuments, hasLength(1));
      expect(
        createdDocuments.first.fields!['status']!.stringValue,
        'flutter/flutter is :green_circle:!',
      );
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
      expect(requests, hasLength(1));
      final content = json.decode(requests.first.body)['content'];
      expect(
        content,
        startsWith('flutter/flutter is :red_circle:! Failing tasks: aaaaaaaaa'),
      );
      expect(
        content,
        endsWith('aaaaa... things appear to be very broken right now. :cry:'),
      );
      expect(createdDocuments, hasLength(1));
      expect(
        createdDocuments.first.fields!['status']!.stringValue,
        'flutter/flutter is :red_circle:! Failing tasks: ${'a' * 2000}',
      );
    });
  });
}
