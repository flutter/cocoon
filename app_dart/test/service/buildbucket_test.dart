// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/utilities/mocks.dart';

void main() {
  group('BatchResponse tests', () {
    test('fromJson returns an empty list', () {
      const String jsonString = '{"responses":[{"searchBuilds":{}},{"searchBuilds":{}}]}';
      final Map<String, dynamic> map = json.decode(jsonString) as Map<String, dynamic>;
      final BatchResponse response = BatchResponse.fromJson(map);
      expect(response, isNotNull);
      expect(response.responses, isNotNull);
    });
  });

  group('Client tests', () {
    late MockClient httpClient;
    late MockAccessTokenService mockAccessTokenProvider;

    const BuilderId builderId = BuilderId(
      bucket: 'prod',
      builder: 'Linux',
      project: 'flutter',
    );

    setUp(() {
      httpClient = MockClient((_) => throw Exception('Client not defined'));
      mockAccessTokenProvider = MockAccessTokenService();
    });

    Future<T> httpTest<R extends JsonBody, T>(
      R request,
      String response,
      String urlPrefix,
      String expectedPath,
      Future<T> Function(BuildBucketClient) requestCallback,
    ) async {
      when(mockAccessTokenProvider.createAccessToken()).thenAnswer((_) async {
        return AccessToken('Bearer', 'data', DateTime.utc(2119));
      });
      httpClient = MockClient((http.Request request) async {
        expect(request.headers['content-type'], 'application/json; charset=utf-8');
        expect(request.headers['accept'], 'application/json');
        expect(request.headers['authorization'], 'Bearer data');
        if (request.method == 'POST' && request.url.toString() == 'https://localhost/$urlPrefix/$expectedPath') {
          return http.Response(
            response,
            HttpStatus.accepted,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
            },
          );
        }
        return http.Response('Test exception: A mock response was not returned', HttpStatus.internalServerError);
      });
      final BuildBucketClient client = BuildBucketClient(
        httpClient: httpClient,
        accessTokenService: mockAccessTokenProvider,
      );
      final T result = await requestCallback(client);
      return result;
    }

    test('Throws the right exception', () async {
      when(mockAccessTokenProvider.createAccessToken()).thenAnswer((_) async {
        return AccessToken('Bearer', 'data', DateTime.utc(2119));
      });
      httpClient = MockClient((_) async => http.Response('Error', HttpStatus.forbidden));
      final BuildBucketClient client = BuildBucketClient(
        buildBucketBuildUri: 'https://localhost',
        httpClient: httpClient,
        accessTokenService: mockAccessTokenProvider,
      );
      try {
        await client.batch(const BatchRequest());
      } on BuildBucketException catch (ex) {
        expect(ex.statusCode, HttpStatus.forbidden);
        expect(ex.message, 'Error');
        return;
      }
      fail('Did not throw expected exception');
    });

    test('ScheduleBuild', () async {
      const ScheduleBuildRequest request = ScheduleBuildRequest(
        builderId: builderId,
        experimental: Trinary.yes,
        tags: <String, List<String>>{
          'user_agent': <String>['flutter_cocoon'],
          'flutter_pr': <String>['true', '1'],
          'cipd_version': <String>['/refs/heads/main'],
        },
        properties: <String, String>{
          'git_url': 'https://github.com/flutter/flutter',
          'git_ref': 'refs/pull/1/head',
        },
      );

      final Build build = await httpTest<ScheduleBuildRequest, Build>(
        request,
        buildJson,
        'builds',
        'ScheduleBuild',
        (BuildBucketClient client) => client.scheduleBuild(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(build.id, '123');
      expect(build.tags!.length, 3);
      expect(build.tags, <String?, List<String?>>{
        'user_agent': <String>['flutter_cocoon'],
        'flutter_pr': <String>['1'],
        'cipd_version': <String>['/refs/heads/main'],
      });
    });

    test('BatchBuildRequest', () async {
      const BatchRequest request = BatchRequest(
        requests: <Request>[
          Request(
            scheduleBuild: ScheduleBuildRequest(
              builderId: builderId,
              experimental: Trinary.yes,
              tags: <String, List<String>>{
                'user_agent': <String>['flutter_cocoon'],
                'flutter_pr': <String>['true', '1'],
                'cipd_version': <String>['/refs/heads/main'],
              },
              properties: <String, String>{
                'git_url': 'https://github.com/flutter/flutter',
                'git_ref': 'refs/pull/1/head',
              },
            ),
          ),
        ],
      );

      final BatchResponse response = await httpTest<BatchRequest, BatchResponse>(
        request,
        batchJson,
        'builds',
        'Batch',
        (BuildBucketClient client) => client.batch(request, buildBucketUri: 'https://localhost/builds'),
      );
      expect(response.responses!.length, 1);
      expect(response.responses!.first.getBuild!.status, Status.success);
      expect(response.responses!.first.getBuild!.tags, <String?, List<String?>>{
        'user_agent': <String>['flutter_cocoon'],
        'flutter_pr': <String>['1'],
        'cipd_version': <String>['/refs/heads/main'],
      });
    });

    test('Batch', () async {
      const BatchRequest request = BatchRequest(
        requests: <Request>[
          Request(
            getBuild: GetBuildRequest(
              builderId: builderId,
              buildNumber: 123,
            ),
          ),
        ],
      );

      final BatchResponse response = await httpTest<BatchRequest, BatchResponse>(
        request,
        batchJson,
        'builds',
        'Batch',
        (BuildBucketClient client) => client.batch(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(response.responses!.length, 1);
      expect(response.responses!.first.getBuild!.status, Status.success);
    });

    test('GetBuild', () async {
      const GetBuildRequest request = GetBuildRequest(
        id: '1234',
      );

      final Build build = await httpTest<GetBuildRequest, Build>(
        request,
        buildJson,
        'builds',
        'GetBuild',
        (BuildBucketClient client) => client.getBuild(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(build.id, '123');
      expect(build.tags!.length, 3);
      expect(build.summaryMarkdown, '```╔═╡ERROR #1╞```');
    });
  });
}

const String builderJson = '''${BuildBucketClient.kRpcResponseGarbage}
{
  "builders": [{
    "id": {
      "project": "flutter",
      "bucket": "prod",
      "builder": "Linux test"
    }
  }, {
    "id": {
      "project": "flutter",
      "bucket": "prod",
      "builder": "Mac test"
    }
  }]
}''';

const String searchJson = '''${BuildBucketClient.kRpcResponseGarbage}
{
  "builds": [
    {
      "status": "SUCCESS",
      "updateTime": "2019-07-26T20:43:52.875240Z",
      "createdBy": "project:flutter",
      "builder": {
        "project": "flutter",
        "builder": "Linux",
        "bucket": "prod"
      },
      "number": 9151,
      "id": "8906840690092270320",
      "startTime": "2019-07-26T20:10:22.271996Z",
      "input": {
        "gitilesCommit": {
          "project": "external/github.com/flutter/flutter",
          "host": "chromium.googlesource.com",
          "ref": "refs/heads/master",
          "id": "3068fc4f7c78599ab4a09b096f0672e8510fc7e6"
        }
      },
      "endTime": "2019-07-26T20:43:52.341494Z",
      "createTime": "2019-07-26T20:10:15.744632Z"
    }
  ]
}''';
const String batchJson = '''${BuildBucketClient.kRpcResponseGarbage}
{
  "responses": [
    {
      "getBuild": {
        "status": "SUCCESS",
        "updateTime": "2019-07-15T23:20:56.930928Z",
        "createdBy": "project:flutter",
        "builder": {
          "project": "flutter",
          "builder": "Linux",
          "bucket": "prod"
        },
        "number": 9000,
        "id": "8907827286280251904",
        "startTime": "2019-07-15T22:49:06.222424Z",
        "input": {
          "gitilesCommit": {
            "project": "external/github.com/flutter/flutter",
            "host": "chromium.googlesource.com",
            "ref": "refs/heads/master",
            "id": "6b17840cbf1a7d7b6208117226ded21a5ec0d55c"
          }
        },
        "endTime": "2019-07-15T23:20:32.610402Z",
        "createTime": "2019-07-15T22:48:44.299749Z",
        "tags": [
          {
            "key": "user_agent",
            "value": "flutter_cocoon"
          },
          {
            "key": "flutter_pr",
            "value": "1"
          },
          {
            "key": "cipd_version",
            "value": "/refs/heads/main"
          }
        ]
      }
    }
  ]
}''';

const String buildJson = '''${BuildBucketClient.kRpcResponseGarbage}
{
  "id": "123",
  "builder": {
    "project": "flutter",
    "bucket": "prod",
    "builder": "Linux"
  },
  "number": 321,
  "createdBy": "cocoon@cocoon",
  "canceledBy": null,
  "startTime": "2019-08-01T11:00:00",
  "endTime": null,
  "status": "SUCCESS",
  "status": "FAILURE",
  "summaryMarkdown": "```╔═╡ERROR #1╞```",
  "input": {
    "experimental": true
  },
  "tags": [{
    "key": "user_agent",
    "value": "flutter_cocoon"
  }, {
    "key": "flutter_pr",
    "value": "1"
  },
  {
            "key": "cipd_version",
            "value": "/refs/heads/main"
          }]
}''';
