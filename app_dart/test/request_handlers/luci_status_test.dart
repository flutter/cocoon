// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:http/testing.dart' as http_test;
import 'package:http/http.dart' as http;
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';

const String ref = 'deadbeef';

void main() {
  const String authToken = '123';
  const String authHeader = 'Bearer $authToken';
  const String deviceLabEmail =
      'flutter-devicelab@flutter-dashboard.iam.gserviceaccount.com';

  LuciStatusHandler handler;
  FakeConfig config;
  MockGitHubClient mockGitHubClient;
  FakeHttpRequest request;
  RequestHandlerTester tester;
  MockRepositoriesService mockRepositoriesService;
  MockBuildBucketClient buildBucketClient;

  setUp(() {
    config = FakeConfig(luciTryInfraFailureRetriesValue: 2);
    buildBucketClient = MockBuildBucketClient();
    handler = LuciStatusHandler(config, buildBucketClient);
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

    mockGitHubClient = MockGitHubClient();
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
          ..state = 'pending',
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
          ..state = 'pending',
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

  test('Reschedules an infra failure', () async {
    request.bodyBytes = utf8.encode(pushMessageJson('COMPLETED',
        builderName: 'Linux',
        result: 'FAILURE',
        failureReason: 'INFRA_FAILURE')) as Uint8List;
    request.headers.add(HttpHeaders.authorizationHeader, authHeader);

    await tester.post(handler);
    expect(
      jsonEncode(
        verify(buildBucketClient.scheduleBuild(captureAny))
            .captured
            .single
            .toJson(),
      ),
      jsonEncode(
        ScheduleBuildRequest(
          builderId: const BuilderId(
            project: 'flutter',
            bucket: 'try',
            builder: 'Linux',
          ),
          tags: const <String, List<String>>{
            'buildset': <String>['pr/git/37647', 'sha/git/$ref'],
            'user_agent': <String>['flutter-cocoon'],
            'github_link': <String>[
              'https://github.com/flutter/flutter/pull/37647'
            ],
          },
          properties: const <String, String>{
            'git_ref': 'refs/pull/37647/head',
            'git_url': 'https://github.com/flutter/flutter',
          },
          notify: NotificationConfig(
            pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
            userData: json.encode(<String, dynamic>{
              'retries': 1,
            }),
          ),
        ).toJson(),
      ),
    );
    verifyNever(mockRepositoriesService.createStatus(
      RepositorySlug('flutter', 'flutter'),
      ref,
      captureAny,
    ));
  });

  test('Does not an infra failure after too many retries', () async {
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
}

class MockGitHubClient extends Mock implements GitHub {}

class MockRepositoriesService extends Mock implements RepositoriesService {}

String pushMessageJson(
  String status, {
  String result,
  String builderName = 'Linux Coverage',
  String urlParam = '',
  int retries = 0,
  String failureReason,
}) {
  return '''{
     "message": {
       "attributes": {},
       "data": "${buildPushMessageJson(status, result: result, builderName: builderName, urlParam: urlParam, retries: retries, failureReason: failureReason)}",
       "messageId": "123"
     },
     "subscription": "projects/myproject/subscriptions/mysubscription"
   }''';
}

String buildPushMessageJson(String status,
        {String result,
        String builderName = 'Linux Coverage',
        String urlParam = '',
        int retries = 0,
        String failureReason}) =>
    base64.encode(
      utf8.encode('''{
  "build": {
    "bucket": "luci.flutter.prod",
    "canary": false,
    "canary_preference": "PROD",
    "created_by": "user:dnfield@google.com",
    "created_ts": "1565049186247524",
    "experimental": false,
    ${failureReason != null ? '"failure_reason": "$failureReason",' : ''}
    "id": "8905920700440101120",
    "parameters_json": "{\\"builder_name\\": \\"$builderName\\", \\"properties\\": {\\"git_ref\\": \\"refs/pull/37647/head\\", \\"git_url\\": \\"https://github.com/flutter/flutter\\"}}",
    "project": "flutter",
    ${result != null ? '"result": "$result",' : ''}
    "result_details_json": "{\\"properties\\": {}, \\"swarming\\": {\\"bot_dimensions\\": {\\"caches\\": [\\"flutter_openjdk_install\\", \\"git\\", \\"goma_v2\\", \\"vpython\\"], \\"cores\\": [\\"8\\"], \\"cpu\\": [\\"x86\\", \\"x86-64\\", \\"x86-64-Broadwell_GCE\\", \\"x86-64-avx2\\"], \\"gce\\": [\\"1\\"], \\"gpu\\": [\\"none\\"], \\"id\\": [\\"luci-flutter-prod-xenial-2-bnrz\\"], \\"image\\": [\\"chrome-xenial-19052201-9cb74617499\\"], \\"inside_docker\\": [\\"0\\"], \\"kvm\\": [\\"1\\"], \\"locale\\": [\\"en_US.UTF-8\\"], \\"machine_type\\": [\\"n1-standard-8\\"], \\"os\\": [\\"Linux\\", \\"Ubuntu\\", \\"Ubuntu-16.04\\"], \\"pool\\": [\\"luci.flutter.prod\\"], \\"python\\": [\\"2.7.12\\"], \\"server_version\\": [\\"4382-5929880\\"], \\"ssd\\": [\\"0\\"], \\"zone\\": [\\"us\\", \\"us-central\\", \\"us-central1\\", \\"us-central1-c\\"]}}}",
    "service_account": "flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com",
    "started_ts": "1565049193786080",
    "status": "$status",
    "status_changed_ts": "1565049194386647",
    "tags": [
      "build_address:luci.flutter.prod/$builderName/1698",
      "builder:$builderName",
      "buildset:pr/git/37647",
      "buildset:sha/git/$ref",
      "github_link:https://github.com/flutter/flutter/pull/37647",
      "swarming_hostname:chromium-swarm.appspot.com",
      "swarming_tag:log_location:logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket.appspot.com/8905920700440101120/+/annotations",
      "swarming_tag:luci_project:flutter",
      "swarming_tag:os:Linux",
      "swarming_tag:recipe_name:flutter/flutter",
      "swarming_tag:recipe_package:infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
      "swarming_task_id:467d04f2f022d510",
      "user_agent:flutter-cocoon"
    ],
    "updated_ts": "1565049194391321",
    "url": "https://ci.chromium.org/b/8905920700440101120$urlParam",
    "utcnow_ts": "1565049194653640"
  },
  "hostname": "cr-buildbucket.appspot.com",
  "user_data": "{\\"retries\\": $retries}"
}'''),
    );

// ignore: must_be_immutable, Test mock.
class MockBuildBucketClient extends Mock implements BuildBucketClient {}
