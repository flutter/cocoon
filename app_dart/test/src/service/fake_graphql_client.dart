// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:graphql/client.dart';
import 'package:graphql/src/core/observable_query.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:test/test.dart';

class FakeGraphQLClient implements GraphQLClient {
  QueryResult Function(MutationOptions) mutateResultForOptions;
  QueryResult Function(QueryOptions) queryResultForOptions;

  @override
  QueryManager queryManager;

  @override
  Cache get cache => throw UnimplementedError();

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
  Stream<FetchResult> subscribe(Operation operation) {
    throw UnimplementedError();
  }

  @override
  ObservableQuery watchQuery(WatchQueryOptions options) {
    throw UnimplementedError();
  }

  void verify(List<BaseOptions> expected, List<BaseOptions> actual) {
    expect(actual.length, expected.length);
    for (int i = 0; i < actual.length; i++) {
      /// [BaseOptions.toKey] serializes all of the relevant parts of the query
      /// or mutation for us, except the fetch policy.
      expect(actual[i].toKey(), expected[i].toKey());
      expect(actual[i].fetchPolicy, expected[i].fetchPolicy);
    }
  }

  void verifyQueries(List<QueryOptions> expected) => verify(expected, queries);

  void verifyMutations(List<MutationOptions> expected) => verify(expected, mutations);

  @override
  DefaultPolicies defaultPolicies;
}
