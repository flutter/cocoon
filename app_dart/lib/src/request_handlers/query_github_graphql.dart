// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';

/// Runs all the applicable tasks for a given PR and commit hash. This will be
/// used to unblock rollers when creating a new commit is not possible.
@immutable
class QueryGithubGraphql extends ApiRequestHandler<Body> {
  const QueryGithubGraphql(
    Config config,
    AuthenticationProvider authenticationProvider,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  @override
  Future<Body> post() async {
    final String requestDataString = String.fromCharCodes(requestBody);
    log.error(requestDataString);
    final GraphQLClient client = await config.createGitHubGraphQLClient();
    final Map<String, dynamic> data = await _queryGraphQL(log, client, requestDataString);
    return Body.forJson(data);
  }

  Future<Map<String, dynamic>> _queryGraphQL(
    Logging log,
    GraphQLClient client,
    String query,
  ) async {
    final QueryResult result = await client.query(
      QueryOptions(
        document: query,
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasErrors) {
      for (GraphQLError error in result.errors) {
        log.error(error.toString());
      }
      throw const BadRequestException('GraphQL query failed');
    }
    return result.data as Map<String, dynamic>;
  }
}
