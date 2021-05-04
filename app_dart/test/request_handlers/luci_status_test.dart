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
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_buildbucket.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

const String ref = 'deadbeef';

void main() {
  const String authToken = '123';
  const String authHeader = 'Bearer $authToken';
  const String deviceLabEmail = 'flutter-devicelab@flutter-dashboard.iam.gserviceaccount.com';

  LuciStatusHandler handler;
  FakeBuildBucketClient buildbucket;
  FakeConfig config;
  MockGitHub mockGitHubClient;
  FakeHttpRequest request;
  RequestHandlerTester tester;
  MockRepositoriesService mockRepositoriesService;
  final FakeLogging log = FakeLogging();
  MockGithubChecksService mockGithubChecksService;

  setUp(() async {
    config = FakeConfig();
    buildbucket = FakeBuildBucketClient();

    mockGithubChecksService = MockGithubChecksService();
    handler = LuciStatusHandler(
      config,
      buildbucket,
      FakeLuciBuildService(config),
      mockGithubChecksService,
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

  test('Requests without repo_owner and repo_name do not update checks', () async {
    request.bodyBytes = utf8.encode(pushMessageJsonNoBuildset(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
    )) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);
    verifyNever(mockGithubChecksService.updateCheckStatus(any, any, any));
  });

  test('Requests with repo_owner and repo_name update checks', () async {
    request.bodyBytes = utf8.encode(pushMessageJson(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
      userData: '{\\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"cocoon\\"}',
    )) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);
    await tester.post(handler);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any)).called(1);
  });
}
