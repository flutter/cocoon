// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:gql/language.dart' as lang;
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/config.dart';
import '../service/logging.dart';

/// Runs an authenticated Github GraphQl query returning the query result as json.
@immutable
class QueryGithubGraphql extends ApiRequestHandler<Body> {
  const QueryGithubGraphql(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting Uint8List? requestBodyValue,
  }) : super(
          config: config,
          authenticationProvider: authenticationProvider,
          requestBodyValue: requestBodyValue,
        );

  @override
  Future<Body> post() async {
    final String requestDataString = String.fromCharCodes(requestBody!);

    if (requestDataString.isEmpty) {
      throw const BadRequestException('Empty request');
    }

    log.info('Received query: $requestDataString');
    final GraphQLClient client = await config.createGitHubGraphQLClient();
    final Map<String, dynamic>? data = await _queryGraphQL(client, requestDataString);
    return Body.forJson(data);
  }

  Future<Map<String, dynamic>?> _queryGraphQL(
    GraphQLClient client,
    String query,
  ) async {
    final QueryResult result = await client.query(
      QueryOptions(
        document: lang.parseString(query),
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasException) {
      log.severe(result.exception.toString());
      throw const BadRequestException('GraphQL query failed');
    }
    return result.data;
  }
}
