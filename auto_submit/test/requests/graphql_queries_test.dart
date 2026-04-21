// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/graphql_queries.dart';
import 'package:gql/language.dart' as lang;
import 'package:test/test.dart';

void main() {
  group('GraphQL Queries', () {
    test('FindPullRequestsWithReviewsQuery includes DISMISSED state', () {
      final query = FindPullRequestsWithReviewsQuery(
        repositoryOwner: 'flutter',
        repositoryName: 'flutter',
        pullRequestNumber: 1,
      );
      final queryString = lang.printNode(query.documentNode);
      expect(
        queryString,
        contains('states: [APPROVED, CHANGES_REQUESTED, DISMISSED]'),
      );
    });
  });
}
