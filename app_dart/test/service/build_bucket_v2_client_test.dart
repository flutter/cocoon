// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/service/build_bucket_v2_client.dart';
import 'package:fixnum/fixnum.dart';
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
      final bbv2.BatchResponse batchResponse = bbv2.BatchResponse().createEmptyInstance();
      batchResponse.mergeFromProto3Json(map);
      expect(batchResponse, isNotNull);
      expect(batchResponse.responses, isNotNull);
    });
  });

  group('Client tests', () {
    late MockClient httpClient;
    late MockAccessTokenService mockAccessTokenProvider;

    final bbv2.BuilderID builderId = bbv2.BuilderID(
      bucket: 'prod',
      builder: 'Linux',
      project: 'flutter',
    );

    setUp(() {
      httpClient = MockClient((_) => throw Exception('Client not defined'));
      mockAccessTokenProvider = MockAccessTokenService();
    });

    Future<T> httpTest<R, T>(
      R request,
      String response,
      String urlPrefix,
      String expectedPath,
      Future<T> Function(BuildBucketV2Client) requestCallback,
    ) async {
      when(mockAccessTokenProvider.createAccessToken()).thenAnswer((_) async {
        return AccessToken('Bearer', 'data', DateTime.utc(2119));
      });
      httpClient = MockClient((http.Request request) async {
        expect(request.headers['content-type'], 'application/json; charset=utf-8');
        expect(request.headers['accept'], 'application/json');
        expect(request.headers['authorization'], 'Bearer data');
        if (request.method == 'POST' && request.url.toString() == 'https://localhost/$urlPrefix/$expectedPath') {
          return http.Response(response, HttpStatus.accepted);
        }
        return http.Response('Test exception: A mock response was not returned', HttpStatus.internalServerError);
      });
      final BuildBucketV2Client client = BuildBucketV2Client(
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
      final BuildBucketV2Client client = BuildBucketV2Client(
        buildBucketBuildUri: 'https://localhost',
        httpClient: httpClient,
        accessTokenService: mockAccessTokenProvider,
      );
      try {
        await client.batch(bbv2.BatchRequest());
      } on BuildBucketException catch (ex) {
        expect(ex.statusCode, HttpStatus.forbidden);
        expect(ex.message, 'Error');
        return;
      }
      fail('Did not throw expected exception');
    });

    test('ScheduleBuild', () async {
      final Map<String, bbv2.Value> propertiesMap = {
        'git_url': bbv2.Value(stringValue:  'https://github.com/flutter/flutter'),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/1/head'),
      };

      final bbv2.ScheduleBuildRequest request = bbv2.ScheduleBuildRequest(
        builder: builderId,
        experimental: bbv2.Trinary.YES,
        tags: <bbv2.StringPair>{
          bbv2.StringPair(key: 'user_agent', value: 'flutter_cocoon'),
          bbv2.StringPair(key: 'flutter_pr', value: 'true'),
          bbv2.StringPair(key: 'flutter_pr', value: '1'),
          bbv2.StringPair(key: 'cipd_version', value: '/refs/heads/main'),
        },
        properties: bbv2.Struct(fields: propertiesMap),
      );

      final bbv2.Build build = await httpTest<bbv2.ScheduleBuildRequest, bbv2.Build>(
        request,
        buildJson,
        'builds',
        'ScheduleBuild',
        (BuildBucketV2Client client) => client.scheduleBuild(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(build.id, Int64(123));
      expect(build.tags.length, 3);
      expect(build.tags, <bbv2.StringPair>{
        bbv2.StringPair(key: 'user_agent', value: 'flutter_cocoon'),
        bbv2.StringPair(key: 'flutter_pr', value: '1'),
        bbv2.StringPair(key: 'cipd_version', value: '/refs/heads/main'),
      });
    });

    test('CancelBuild', () async {
      final bbv2.CancelBuildRequest request = bbv2.CancelBuildRequest(
        id: Int64(1234),
        summaryMarkdown: 'Because I felt like it.',
      );

      final bbv2.Build build = await httpTest<bbv2.CancelBuildRequest, bbv2.Build>(
        request,
        buildJson,
        'builds',
        'CancelBuild',
        (BuildBucketV2Client client) => client.cancelBuild(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(build.id, Int64(123));
      expect(build.tags.length, 3);
    });

    test('BatchBuildRequest', () async {
      final Map<String, bbv2.Value> propertiesMap = {
        'git_url': bbv2.Value(stringValue:  'https://github.com/flutter/flutter'),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/1/head'),
      };

      final bbv2.BatchRequest request = bbv2.BatchRequest(
        requests: <bbv2.BatchRequest_Request>[
          bbv2.BatchRequest_Request(
            scheduleBuild: bbv2.ScheduleBuildRequest(
              builder: builderId,
              experimental: bbv2.Trinary.YES,
              tags: <bbv2.StringPair>{
                bbv2.StringPair(key: 'user_agent', value: 'flutter_cocoon'),
                bbv2.StringPair(key: 'flutter_pr', value: 'true'),
                bbv2.StringPair(key: 'flutter_pr', value: '1'),
                bbv2.StringPair(key: 'cipd_version', value: '/refs/heads/main'),
              },
              properties: bbv2.Struct(fields: propertiesMap),
            ),
          ),
        ],
      );

      final bbv2.BatchResponse response = await httpTest<bbv2.BatchRequest, bbv2.BatchResponse>(
        request,
        batchJson,
        'builds',
        'Batch',
        (BuildBucketV2Client client) => client.batch(request, buildBucketUri: 'https://localhost/builds'),
      );
      expect(response.responses.length, 1);
      expect(response.responses.first.getBuild.status, bbv2.Status.SUCCESS);
      expect(response.responses.first.getBuild.tags, <bbv2.StringPair>{
        bbv2.StringPair(key: 'user_agent', value: 'flutter_cocoon'),
        bbv2.StringPair(key: 'flutter_pr', value: '1'),
        bbv2.StringPair(key: 'cipd_version', value: '/refs/heads/main'),
      });
    });

    test('Batch', () async {
      final bbv2.BatchRequest request = bbv2.BatchRequest(
        requests: <bbv2.BatchRequest_Request>[
          bbv2.BatchRequest_Request(
            getBuild: bbv2.GetBuildRequest(
              builder: builderId,
              buildNumber: 123,
            ),
          ),
        ],
      );

      final bbv2.BatchResponse response = await httpTest<bbv2.BatchRequest, bbv2.BatchResponse>(
        request,
        batchJson,
        'builds',
        'Batch',
        (BuildBucketV2Client client) => client.batch(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(response.responses.length, 1);
      expect(response.responses.first.getBuild.status, bbv2.Status.SUCCESS);
    });

    test('GetBuild', () async {
      final bbv2.GetBuildRequest request = bbv2.GetBuildRequest(
        id: Int64(1234),
      );

      final bbv2.Build build = await httpTest<bbv2.GetBuildRequest, bbv2.Build>(
        request,
        buildJson,
        'builds',
        'GetBuild',
        (BuildBucketV2Client client) => client.getBuild(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(build.id, Int64(123));
      expect(build.tags.length, 3);
    });

    test('SearchBuilds', () async {
      final bbv2.SearchBuildsRequest request = bbv2.SearchBuildsRequest(
        predicate: bbv2.BuildPredicate(
          tags: <bbv2.StringPair>{
            bbv2.StringPair(key: 'flutter_pr', value: '1'),
          },
        ),
      );

      final bbv2.SearchBuildsResponse response = await httpTest<bbv2.SearchBuildsRequest, bbv2.SearchBuildsResponse>(
        request,
        searchJson,
        'builds',
        'SearchBuilds',
        (BuildBucketV2Client client) => client.searchBuilds(request, buildBucketUri: 'https://localhost/builds'),
      );

      expect(response.builds.length, 1);
      expect(response.builds.first.number, 9151);
    });

    test('ListBuilders', () async {
      final bbv2.ListBuildersRequest request = bbv2.ListBuildersRequest(project: 'test');

      final bbv2.ListBuildersResponse listBuildersResponse = await httpTest<bbv2.ListBuildersRequest, bbv2.ListBuildersResponse>(
        request,
        builderJson,
        'builders',
        'ListBuilders',
        (BuildBucketV2Client client) => client.listBuilders(request, buildBucketUri: 'https://localhost/builders'),
      );

      expect(listBuildersResponse.builders.length, 2);
      expect(listBuildersResponse.builders.map((e) => e.id.builder).toList(), <String>['Linux test', 'Mac test']);
    });
  });
}

const String builderJson = '''${BuildBucketV2Client.kRpcResponseGarbage}
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

const String searchJson = '''${BuildBucketV2Client.kRpcResponseGarbage}
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

const String batchJson = '''${BuildBucketV2Client.kRpcResponseGarbage}
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

const String buildJson = '''${BuildBucketV2Client.kRpcResponseGarbage}
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
  "status": "SCHEDULED",
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
