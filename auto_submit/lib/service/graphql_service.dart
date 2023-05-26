// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/log.dart';
import 'package:gql/ast.dart';
import 'package:graphql/client.dart';

import '../requests/exceptions.dart';

/// Service class used to execute GraphQL queries.
class GraphQlService {
  /// Runs a GraphQL query using [slug], [prNumber] and a [GraphQL] client.
  Future<Map<String, dynamic>> queryGraphQL({
    required DocumentNode documentNode,
    required Map<String, dynamic> variables,
    required GraphQLClient client,
  }) async {
    final QueryResult queryResult = await client.query(
      QueryOptions(
        document: documentNode,
        fetchPolicy: FetchPolicy.noCache,
        variables: variables,
      ),
    );

    if (queryResult.hasException) {
      log.severe(queryResult.exception.toString());
      throw const BadRequestException('GraphQL query failed');
    }
    return queryResult.data!;
  }

  Future<Map<String, dynamic>> mutateGraphQL({
    required DocumentNode documentNode,
    required Map<String, dynamic> variables,
    required GraphQLClient client,
  }) async {
    final QueryResult queryResult = await client.mutate(
      MutationOptions(
        document: documentNode,
        fetchPolicy: FetchPolicy.noCache,
        variables: variables,
      ),
    );

    if (queryResult.hasException) {
      log.severe(queryResult.exception.toString());
      throw const BadRequestException('GraphQL mutate failed');
    }
    return queryResult.data!;
  }
}
