// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/src/request_handlers/query_github_graphql.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('Query Github Grapql', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    QueryGithubGraphql handler;
    FakeHttpRequest request;

    setUp(() {
      request = FakeHttpRequest();
      tester = ApiRequestHandlerTester(request: request);
      config = FakeConfig();
      handler = QueryGithubGraphql(
        config,
        FakeAuthenticationProvider(),
        requestBodyValue: utf8.encode('myquery') as Uint8List,
      );
      config.githubGraphQLClient = MockGraphQLClient();
    });

    test('Empty body raises a bad request exception', () async {
      handler = QueryGithubGraphql(
        config,
        FakeAuthenticationProvider(),
        requestBodyValue: utf8.encode('') as Uint8List,
      );
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Successful query', () async {
      when(config.githubGraphQLClient.query(any)).thenAnswer((_) async {
        return QueryResult(data: <String, dynamic>{'result': true});
      });
      final Body body = await tester.post(handler);
      final Map<String, dynamic> result =
          await utf8.decoder.bind(body.serialize()).transform(json.decoder).single as Map<String, dynamic>;
      expect(result['result'], isTrue);
    });

    test('Query with errors', () async {
      when(config.githubGraphQLClient.query(any)).thenAnswer((_) async {
        return QueryResult(errors: <GraphQLError>[GraphQLError(message: 'first error')]);
      });
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });
  });
}

class MockGraphQLClient extends Mock implements GraphQLClient {}
