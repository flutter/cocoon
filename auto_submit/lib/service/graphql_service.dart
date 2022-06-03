// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';

import '../requests/exceptions.dart';

/// Service class used to execute GraphQL queries.
class GraphQlService {
  /// Runs a GraphQL query using [slug], [prNumber] and a [GraphQL] client.
  Future<Map<String, dynamic>> queryGraphQL(
    RepositorySlug slug,
    int prNumber,
    GraphQLClient client,
  ) async {
    final QueryResult result = await client.query(
      QueryOptions(
        document: pullRequestWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'sOwner': slug.owner,
          'sName': slug.name,
          'sPrNumber': prNumber,
        },
      ),
    );

    if (result.hasException) {
      log.severe(result.exception.toString());
      throw const BadRequestException('GraphQL query failed');
    }
    return result.data!;
  }
}
