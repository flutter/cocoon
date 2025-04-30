// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gql/ast.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

class FakeGraphQLClient implements GraphQLClient {
  late QueryResult Function(MutationOptions) mutateResultForOptions;
  late QueryResult Function(QueryOptions) queryResultForOptions;

  @override
  late QueryManager queryManager;

  @override
  Link get link => throw UnimplementedError();

  final List<QueryOptions> queries = <QueryOptions>[];
  final List<MutationOptions> mutations = <MutationOptions>[];

  @override
  Future<QueryResult<T>> mutate<T>(MutationOptions options) async {
    mutations.add(options);
    return mutateResultForOptions(options) as QueryResult<T>;
  }

  @override
  Future<QueryResult<T>> query<T>(QueryOptions options) async {
    queries.add(options);
    return queryResultForOptions(options) as QueryResult<T>;
  }

  void verifyQueries(List<QueryOptions> expected) {
    expect(queries.length, expected.length);
    for (var i = 0; i < queries.length; i++) {
      expect(queries[i].properties, equals(expected[i].properties));
    }
  }

  void verifyMutations(List<MutationOptions> expected) {
    expect(mutations.length, expected.length);
    for (var i = 0; i < mutations.length; i++) {
      expect(mutations[i].properties, equals(expected[i].properties));
    }
  }

  @override
  late DefaultPolicies defaultPolicies;

  @override
  Map<String, dynamic> readFragment(
    FragmentRequest fragmentRequest, {
    bool? optimistic = true,
  }) {
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
  void writeFragment(
    FragmentRequest fragmentRequest, {
    bool? broadcast = true,
    Map<String, dynamic>? data,
  }) {}

  @override
  void writeQuery(
    Request request, {
    Map<String, dynamic>? data,
    bool? broadcast = true,
  }) {}

  @override
  GraphQLCache get cache => throw UnimplementedError();

  @override
  GraphQLClient copyWith({
    Link? link,
    GraphQLCache? cache,
    DefaultPolicies? defaultPolicies,
    bool? alwaysRebroadcast,
    DeepEqualsFn? deepEquals,
    bool deduplicatePollers = false,
    Duration? queryRequestTimeout,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<QueryResult<T>> fetchMore<T>(
    FetchMoreOptions fetchMoreOptions, {
    required QueryOptions<T> originalOptions,
    required QueryResult<T> previousResult,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<QueryResult<T>> subscribe<T>(SubscriptionOptions<T> options) {
    throw UnimplementedError();
  }

  @override
  ObservableQuery<T> watchMutation<T>(WatchQueryOptions<T> options) {
    throw UnimplementedError();
  }

  @override
  ObservableQuery<T> watchQuery<T>(WatchQueryOptions<T> options) {
    throw UnimplementedError();
  }
}

QueryResult createFakeQueryResult({
  Map<String, dynamic>? data,
  OperationException? exception,
}) => QueryResult(
  data: data,
  exception: exception,
  options: QueryOptions(document: const DocumentNode()),
  source: QueryResultSource.network,
);
