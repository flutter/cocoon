// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gql/ast.dart';
import 'package:graphql/client.dart';
import 'package:graphql/src/core/result_parser.dart';
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
  Future<QueryResult<TParsed>> mutate<TParsed>(MutationOptions options) async {
    mutations.add(options);
    return mutateResultForOptions(options) as QueryResult<TParsed>;
  }

  @override
  Future<QueryResult<TParsed>> query<TParsed>(QueryOptions options) async {
    queries.add(options);
    return queryResultForOptions(options) as QueryResult<TParsed>;
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
  void writeFragment(FragmentRequest fragmentRequest, {bool? broadcast = true, Map<String, dynamic>? data}) {}

  @override
  void writeQuery(Request request, {Map<String, dynamic>? data, bool? broadcast = true}) {}

  @override
  GraphQLCache get cache => throw UnimplementedError();

  @override
  GraphQLClient copyWith({
    Link? link,
    GraphQLCache? cache,
    DefaultPolicies? defaultPolicies,
    bool? alwaysRebroadcast,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<QueryResult<TParsed>> fetchMore<TParsed>(FetchMoreOptions fetchMoreOptions,
      {required QueryOptions<TParsed> originalOptions, required QueryResult<TParsed> previousResult}) {
    throw UnimplementedError();
  }

  @override
  Stream<QueryResult<TParsed>> subscribe<TParsed>(SubscriptionOptions<TParsed> options) {
    throw UnimplementedError();
  }

  @override
  ObservableQuery<TParsed> watchMutation<TParsed>(WatchQueryOptions<TParsed> options) {
    throw UnimplementedError();
  }

  @override
  ObservableQuery<TParsed> watchQuery<TParsed>(WatchQueryOptions<TParsed> options) {
    throw UnimplementedError();
  }
}

QueryResult createFakeQueryResult({
  Map<String, dynamic>? data,
  OperationException? exception,
}) =>
    QueryResult(
      data: data,
      exception: exception,
      options: QueryOptions(
        document: const DocumentNode(),
      ),
      source: QueryResultSource.network,
    );
