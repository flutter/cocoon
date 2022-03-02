// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/log.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

import 'exceptions.dart';
import 'refresh_cirrus_status_queries.dart';

/// Refer all cirrus build statuses at: https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql#L120
const List<String> kCirrusFailedStates = <String>[
  'ABORTED',
  'FAILED',
];
const List<String> kCirrusInProgressStates = <String>[
  'CREATED',
  'TRIGGERED',
  'SCHEDULED',
  'EXECUTING',
  'PAUSED'
];

class CirrusGraphQLClient implements GraphQLClient {
  /// Constructs a [GraphQLClient] given a [Link] and a [Cache].
  CirrusGraphQLClient({
    required this.link,
    required this.cache,
    DefaultPolicies? defaultPolicies,
    bool alwaysRebroadcast = false,
  })  : defaultPolicies = defaultPolicies ?? DefaultPolicies(),
        queryManager = QueryManager(
          link: link,
          cache: cache,
          alwaysRebroadcast: alwaysRebroadcast,
        );

  @override
  final Link link;

  @override
  final GraphQLCache cache;

  late QueryResult Function(MutationOptions) mutateResultForOptions;
  late QueryResult Function(QueryOptions) queryResultForOptions;

  @override
  late QueryManager queryManager;

  final List<QueryOptions> queries = <QueryOptions>[];
  final List<MutationOptions> mutations = <MutationOptions>[];

  @override
  Future<QueryResult> mutate(MutationOptions options) async {
    mutations.add(options);
    return mutateResultForOptions(options);
  }

  @override
  Future<QueryResult> query(QueryOptions options) async {
    queries.add(options);
    return queryResultForOptions(options);
  }

  @override
  ObservableQuery watchQuery(WatchQueryOptions options) {
    throw UnimplementedError();
  }

  void verifyQueries(List<QueryOptions> expected) {
    expect(queries.length, expected.length);
    for (int i = 0; i < queries.length; i++) {
      expect(
        queries[i].properties,
        equals(expected[i].properties),
      );
    }
  }

  void verifyMutations(List<MutationOptions> expected) {
    expect(mutations.length, expected.length);
    for (int i = 0; i < mutations.length; i++) {
      expect(
        mutations[i].properties,
        equals(expected[i].properties),
      );
    }
  }

  @override
  late DefaultPolicies defaultPolicies;

  @override
  Future<QueryResult> fetchMore(FetchMoreOptions fetchMoreOptions,
      {QueryOptions? originalOptions, QueryResult? previousResult}) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> readFragment(FragmentRequest fragmentRequest,
      {bool? optimistic = true}) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> readQuery(Request request, {bool? optimistic = true}) {
    throw UnimplementedError();
  }

  @override
  Future<List<QueryResult>> resetStore({bool refetchQueries = true}) {
    throw UnimplementedError();
  }

  @override
  ObservableQuery watchMutation(WatchQueryOptions options) {
    throw UnimplementedError();
  }

  @override
  void writeFragment(FragmentRequest fragmentRequest,
      {bool? broadcast = true, Map<String, dynamic>? data}) {}

  @override
  void writeQuery(Request request,
      {Map<String, dynamic>? data, bool? broadcast = true}) {}

  @override
  Stream<QueryResult> subscribe(SubscriptionOptions options) {
    throw UnimplementedError();
  }

  Future<List<CirrusResult>> queryCirrusGraphQL(
    String sha,
    String name,
  ) async {
    const String owner = 'flutter';
    final QueryResult result = await query(
      QueryOptions(
        document: cirusStatusQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'owner': owner,
          'name': name,
          'SHA': sha,
        },
      ),
    );

    if (result.hasException) {
      logger.severe(result.exception.toString());
      throw const BadRequestException('GraphQL query failed');
    }

    final List<Map<String, dynamic>> tasks = <Map<String, dynamic>>[];
    final List<CirrusResult> cirrusResults = <CirrusResult>[];
    String? branch;
    if (result.data == null) {
      cirrusResults.add(CirrusResult(branch, tasks));
      return cirrusResults;
    }
    try {
      final List<dynamic> searchBuilds =
          result.data!['searchBuilds'] as List<dynamic>;
      for (dynamic searchBuild in searchBuilds) {
        tasks.clear();
        tasks.addAll((searchBuild['latestGroupTasks'] as List<dynamic>)
            .cast<Map<String, dynamic>>());
        branch = searchBuild['branch'] as String?;
        cirrusResults.add(CirrusResult(branch, tasks));
      }
    } catch (_) {
      logger.fine(
          'Did not receive expected result from Cirrus, sha $sha may not be executing Cirrus tasks.');
    }
    return cirrusResults;
  }
}

class CirrusResult {
  const CirrusResult(this.branch, this.tasks);

  final String? branch;
  final List<Map<String, dynamic>> tasks;
}
