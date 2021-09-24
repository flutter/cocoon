// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      /// [BaseOptions.toKey] serializes all of the relevant parts of the query
      /// or mutation for us, except the fetch policy.
      expect(queries[i].toString(), expected[i].toString());
      expect(queries[i].fetchPolicy, expected[i].fetchPolicy);
    }
  }

  void verifyMutations(List<MutationOptions> expected) {
    expect(mutations.length, expected.length);
    for (int i = 0; i < mutations.length; i++) {
      /// [BaseOptions.toKey] serializes all of the relevant parts of the query
      /// or mutation for us, except the fetch policy.
      expect(mutations[i].toString(), expected[i].toString());
      expect(mutations[i].fetchPolicy, expected[i].fetchPolicy);
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
  Map<String, dynamic> readFragment(FragmentRequest fragmentRequest, {bool? optimistic = true}) {
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
  void writeFragment(FragmentRequest fragmentRequest, {bool? broadcast = true, Map<String, dynamic>? data}) {}

  @override
  void writeQuery(Request request, {Map<String, dynamic>? data, bool? broadcast = true}) {}

  @override
  GraphQLCache get cache => throw UnimplementedError();

  @override
  Stream<QueryResult> subscribe(SubscriptionOptions options) {
    throw UnimplementedError();
  }
}
