// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:http/testing.dart' as http_test;
import 'package:http/http.dart' as http;
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

const String ref = 'deadbeef';

void main() {
  const String authToken = '123';
  const String authHeader = 'Bearer $authToken';
  const String deviceLabEmail =
      'flutter-devicelab@flutter-dashboard.iam.gserviceaccount.com';

  LuciStatusHandler handler;
  FakeConfig config;
  MockGitHub mockGitHubClient;
  FakeHttpRequest request;
  RequestHandlerTester tester;
  MockRepositoriesService mockRepositoriesService;
  MockBuildBucketClient buildBucketClient;
  final FakeLogging log = FakeLogging();

  setUp(() {
    config = FakeConfig(luciTryInfraFailureRetriesValue: 2);
    buildBucketClient = MockBuildBucketClient();
    handler = LuciStatusHandler(
      config,
      buildBucketClient,
      loggingProvider: () => log,
    );
    request = FakeHttpRequest();

    tester = RequestHandlerTester(
      request: request,
      httpClient: http_test.MockClient((http.BaseRequest request) async {
        expect(
          request.url.toString(),
          'https://www.googleapis.com/oauth2/v2/tokeninfo?id_token=$authToken&alt=json',
        );
        return http.Response(
          '''{
            "issued_to": "456",
            "audience": "https://flutter-dashboard.appspot.com/api/luci-status-handler",
            "user_id": "789",
            "expires_in": 123,
            "email": "$deviceLabEmail",
            "verified_email": true,
            "issuer": "https://accounts.google.com",
            "issued_at": 412321
          }''',
          200,
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        );
      }),
    );

    config.luciTryBuildersValue = (json.decode('''[
      {"name": "Linux", "repo": "flutter", "taskName": "linux_bot"},
      {"name": "Mac", "repo": "flutter", "taskName": "mac_bot"},
      {"name": "Windows", "repo": "flutter", "taskName": "windows_bot"},
      {"name": "Linux Coverage", "repo": "flutter"},
      {"name": "Linux Host Engine", "repo": "engine"},
      {"name": "Linux Android AOT Engine", "repo": "engine"},
      {"name": "Linux Android Debug Engine", "repo": "engine"},
      {"name": "Mac Host Engine", "repo": "engine"},
      {"name": "Mac Android AOT Engine", "repo": "engine"},
      {"name": "Mac Android Debug Engine", "repo": "engine"},
      {"name": "Mac iOS Engine", "repo": "engine"},
      {"name": "Windows Host Engine", "repo": "engine"},
      {"name": "Windows Android AOT Engine", "repo": "engine"}
    ]''') as List<dynamic>).cast<Map<String, dynamic>>();

    mockGitHubClient = MockGitHub();
    mockRepositoriesService = MockRepositoriesService();
    when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
    config.githubClient = mockGitHubClient;
    config.deviceLabServiceAccountValue = const ServiceAccountInfo(
      email: deviceLabEmail,
    );
  });

  test('Rejects unauthorized requests', () async {
    request.bodyBytes = utf8.encode(pushMessageJson('SCHEDULED')) as Uint8List;
    await expectLater(
      () => tester.post(handler),
      throwsA(const TypeMatcher<Unauthorized>()),
    );
  });

  group('pending', () {
    List<RepositoryStatus> repositoryStatuses;
    setUp(() {
      when(mockRepositoriesService.listStatuses(any, ref)).thenAnswer((_) {
        return Stream<RepositoryStatus>.fromIterable(repositoryStatuses);
      });
    });

    tearDown(() {
      repositoryStatuses = null;
    });

    test('Handles a scheduled status as pending and pending is not most recent',
        () async {
      repositoryStatuses = <RepositoryStatus>[
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'failure',
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'pending',
      ];
      request.bodyBytes =
          utf8.encode(pushMessageJson('SCHEDULED')) as Uint8List;
      request.headers.add(HttpHeaders.authorizationHeader, authHeader);

      await tester.post(handler);
      expect(
        verify(mockRepositoriesService.createStatus(
          RepositorySlug('flutter', 'flutter'),
          ref,
          captureAny,
        )).captured.single.toJson(),
        jsonDecode(
            '{"state":"pending","target_url":"https://ci.chromium.org/b/8905920700440101120?reload=30","description":"Flutter LUCI Build: Linux Coverage","context":"Linux Coverage"}'),
      );
    });

    test(
        'Handles a scheduled status as pending and pending is not most recent with query param',
        () async {
      repositoryStatuses = <RepositoryStatus>[
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'failure',
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'pending',
      ];
      request.bodyBytes =
          utf8.encode(pushMessageJson('SCHEDULED', urlParam: '?foo=bar'))
              as Uint8List;
      request.headers.add(HttpHeaders.authorizationHeader, authHeader);

      await tester.post(handler);
      expect(
        verify(mockRepositoriesService.createStatus(
          RepositorySlug('flutter', 'flutter'),
          ref,
          captureAny,
        )).captured.single.toJson(),
        jsonDecode(
            '{"state":"pending","target_url":"https://ci.chromium.org/b/8905920700440101120?foo=bar&reload=30","description":"Flutter LUCI Build: Linux Coverage","context":"Linux Coverage"}'),
      );
    });

    test('Handles a scheduled status as pending and pending already set',
        () async {
      repositoryStatuses = <RepositoryStatus>[
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'pending'
          ..targetUrl = 'https://ci.chromium.org/b/8905920700440101120',
      ];
      request.bodyBytes =
          utf8.encode(pushMessageJson('SCHEDULED')) as Uint8List;
      request.headers.add(HttpHeaders.authorizationHeader, authHeader);

      await tester.post(handler);
      verifyNever(mockRepositoriesService.createStatus(
        RepositorySlug('flutter', 'flutter'),
        ref,
        any,
      ));
    });

    test('Handles a started status as pending and most recent is not pending',
        () async {
      repositoryStatuses = <RepositoryStatus>[
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'failure',
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'pending',
      ];
      request.bodyBytes = utf8.encode(pushMessageJson('STARTED')) as Uint8List;
      request.headers.add(HttpHeaders.authorizationHeader, authHeader);

      await tester.post(handler);
      expect(
        verify(mockRepositoriesService.createStatus(
          RepositorySlug('flutter', 'flutter'),
          ref,
          captureAny,
        )).captured.single.toJson(),
        jsonDecode(
            '{"state":"pending","target_url":"https://ci.chromium.org/b/8905920700440101120?reload=30","description":"Flutter LUCI Build: Linux Coverage","context":"Linux Coverage"}'),
      );
    });

    test('Handles a started status as pending and pending already set',
        () async {
      repositoryStatuses = <RepositoryStatus>[
        RepositoryStatus()
          ..context = 'Linux Coverage'
          ..state = 'pending'
          ..targetUrl = 'https://ci.chromium.org/b/8905920700440101120',
      ];
      request.bodyBytes = utf8.encode(pushMessageJson('STARTED')) as Uint8List;
      request.headers.add(HttpHeaders.authorizationHeader, authHeader);

      await tester.post(handler);
      verifyNever(mockRepositoriesService.createStatus(
          RepositorySlug('flutter', 'flutter'), ref, any));
    });
  });

  test('Handles a completed/failure status/result as failure', () async {
    request.bodyBytes = utf8
        .encode(pushMessageJson('COMPLETED', result: 'FAILURE')) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);
    expect(
      verify(mockRepositoriesService.createStatus(
        RepositorySlug('flutter', 'flutter'),
        ref,
        captureAny,
      )).captured.single.toJson(),
      jsonDecode(
          '{"state":"failure","target_url":"https://ci.chromium.org/b/8905920700440101120","description":"Flutter LUCI Build: Linux Coverage","context":"Linux Coverage"}'),
    );
  });

  test('Does not schedule after too many retries with infra failure', () async {
    request.bodyBytes = utf8.encode(pushMessageJson('COMPLETED',
        builderName: 'Linux',
        result: 'FAILURE',
        failureReason: 'INFRA_FAILURE',
        retries: 2)) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);

    verifyNever(buildBucketClient.scheduleBuild(any));
    expect(
      verify(mockRepositoriesService.createStatus(
        RepositorySlug('flutter', 'flutter'),
        ref,
        captureAny,
      )).captured.single.toJson(),
      jsonDecode(
          '{"state":"failure","target_url":"https://ci.chromium.org/b/8905920700440101120","description":"Flutter LUCI Build: Linux","context":"Linux"}'),
    );
  });

  test('Handles a completed/canceled status/result as failure', () async {
    request.bodyBytes = utf8
        .encode(pushMessageJson('COMPLETED', result: 'CANCELED')) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);
    expect(
      verify(mockRepositoriesService.createStatus(
        RepositorySlug('flutter', 'flutter'),
        ref,
        captureAny,
      )).captured.single.toJson(),
      jsonDecode(
          '{"state":"failure","target_url":"https://ci.chromium.org/b/8905920700440101120","description":"Flutter LUCI Build: Linux Coverage","context":"Linux Coverage"}'),
    );
  });

  test('Handles a completed/success status/result as sucess', () async {
    request.bodyBytes = utf8
        .encode(pushMessageJson('COMPLETED', result: 'SUCCESS')) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);
    expect(
      verify(mockRepositoriesService.createStatus(
        RepositorySlug('flutter', 'flutter'),
        ref,
        captureAny,
      )).captured.single.toJson(),
      jsonDecode(
          '{"state":"success","target_url":"https://ci.chromium.org/b/8905920700440101120","description":"Flutter LUCI Build: Linux Coverage","context":"Linux Coverage"}'),
    );
  });

  test('Handles engine builder', () async {
    request.bodyBytes = utf8.encode(pushMessageJson(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
    )) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);
    expect(
      verify(mockRepositoriesService.createStatus(
        RepositorySlug('flutter', 'engine'),
        ref,
        captureAny,
      )).captured.single.toJson(),
      jsonDecode(
          '{"state":"success","target_url":"https://ci.chromium.org/b/8905920700440101120","description":"Flutter LUCI Build: Linux Host Engine","context":"Linux Host Engine"}'),
    );
  });

  test('Requests without buildset skip status updates', () async {
    request.bodyBytes = utf8.encode(pushMessageJsonNoBuildset(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
    )) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);
    verifyNever(mockRepositoriesService.createStatus(any, any, any));
  });
}
