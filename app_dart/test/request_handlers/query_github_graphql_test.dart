// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/src/request_handlers/query_github_graphql.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';
import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/service/fake_graphql_client.dart';

void main() {
  group('Query Github Grapql', () {
    late FakeConfig config;
    late ApiRequestHandlerTester tester;
    late FakeGraphQLClient graphqlClient;
    late QueryGithubGraphql handler;
    FakeHttpRequest request;

    const String graphQLHelloWorld = r'''
      type Query {
        hello: String
      }
    ''';

    setUp(() {
      request = FakeHttpRequest();
      tester = ApiRequestHandlerTester(request: request);
      graphqlClient = FakeGraphQLClient();
      config = FakeConfig(githubGraphQLClient: graphqlClient);
      handler = QueryGithubGraphql(
        config: config,
        authenticationProvider: FakeAuthenticationProvider(),
        requestBodyValue: utf8.encode(graphQLHelloWorld),
      );
    });

    test('Empty body raises a bad request exception', () async {
      handler = QueryGithubGraphql(
        config: config,
        authenticationProvider: FakeAuthenticationProvider(),
        requestBodyValue: utf8.encode(''),
      );
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Successful query', () async {
      graphqlClient.queryResultForOptions = (_) => createFakeQueryResult(
            data: <String, dynamic>{'result': true},
          );
      final Body body = await tester.post(handler);
      final Map<String, dynamic> result = await utf8.decoder
          .bind(body.serialize() as Stream<List<int>>)
          .transform(json.decoder)
          .single as Map<String, dynamic>;
      expect(result['result'], isTrue);
    });

    test('Query with errors', () async {
      graphqlClient.queryResultForOptions = (_) => createFakeQueryResult(
            exception: OperationException(),
          );
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });
  });
}
