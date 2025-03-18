// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;
import 'package:gql/ast.dart';
import 'package:graphql/client.dart';

import '../requests/exceptions.dart';
import '../requests/graphql_queries.dart';
import 'config.dart';

/// Service class used to execute GraphQL queries.
class GraphQlService {
  GraphQlService._(this._client);

  // TODO(yjbanov): GraphQlService should not be slug-specific (i.e. repo-specific); you
  //                only need the "owner" (i.e. the Github org or user). Making it
  //                slug-specific makes it awkward to use for org operations and cross-repo
  //                operations.
  static Future<GraphQlService> forRepo(
    Config config,
    github.RepositorySlug slug,
  ) async {
    final client = await config.createGitHubGraphQLClient(slug);
    return GraphQlService._(client);
  }

  final GraphQLClient _client;

  /// Runs a GraphQL query using [slug], [prNumber] and a [GraphQL] client.
  // TODO(yjbanov): make this private, and instead expose higher-level testable
  //                and mockable methods that perform specific queries.
  Future<Map<String, dynamic>> queryGraphQL({
    required DocumentNode documentNode,
    required Map<String, dynamic> variables,
  }) async {
    final queryResult = await _client.query(
      QueryOptions(
        document: documentNode,
        fetchPolicy: FetchPolicy.noCache,
        variables: variables,
      ),
    );

    if (queryResult.hasException) {
      log2.error('GraphQL query failed', queryResult.exception);
      throw const BadRequestException('GraphQL query failed');
    }
    return queryResult.data!;
  }

  // TODO(yjbanov): make this private, and instead expose higher-level testable
  //                and mockable methods that perform specific mutations.
  Future<Map<String, dynamic>> mutateGraphQL({
    required DocumentNode documentNode,
    required Map<String, dynamic> variables,
  }) async {
    final queryResult = await _client.mutate(
      MutationOptions(
        document: documentNode,
        fetchPolicy: FetchPolicy.noCache,
        variables: variables,
      ),
    );

    if (queryResult.hasException) {
      log2.error('GraphQL mutate failed', queryResult.exception);
      throw const BadRequestException('GraphQL mutate failed');
    }
    return queryResult.data!;
  }

  /// Retrieves the GraphQL ID for a pull request.
  ///
  /// The REST pull request ID is not the same as the GraphQL ID, and GraphQL
  /// mutations only accept the GraphQL variant.
  Future<String> getPullRequestId(
    github.RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    final queryPullRequest = FindPullRequestNodeIdQuery(
      repositoryOwner: slug.owner,
      repositoryName: slug.name,
      pullRequestNumber: pullRequestNumber,
    );

    final graphQlPullRequest = await queryGraphQL(
      documentNode: queryPullRequest.documentNode,
      variables: queryPullRequest.variables,
    );

    return graphQlPullRequest['repository']['pullRequest']['id'] as String;
  }

  /// Puts the given pull request onto the merge queue.
  ///
  /// Assumes merge queue is enabled in the respective repository, and that the
  /// pull request is in a state that allows it to proceed onto the merge queue
  /// (e.g. all required checks pass).
  Future<void> enqueuePullRequest(
    github.RepositorySlug slug,
    int pullRequestNumber,
    bool jump,
  ) async {
    final enqueueMutation = EnqueuePullRequestMutation(
      id: await getPullRequestId(slug, pullRequestNumber),
      jump: jump,
    );

    log2.info(
      'Attempting to enqueue ${slug.fullName}/$pullRequestNumber '
      'with these variables: ${enqueueMutation.variables}',
    );

    await mutateGraphQL(
      documentNode: enqueueMutation.documentNode,
      variables: enqueueMutation.variables,
    );
  }
}

extension QueryOptionsExtension on QueryOptions {
  String? get operationDefinitionName {
    return document.definitions
        .whereType<OperationDefinitionNode>()
        .map<String?>((operation) => operation.name?.value)
        .firstOrNull;
  }
}
