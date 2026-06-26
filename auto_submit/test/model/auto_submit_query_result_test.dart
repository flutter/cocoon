// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late QueryResult queryResult;

  group('Auto Submit Models', () {
    setUp(() {
      queryResult = QueryResult.fromJson(data);
    });

    test('repository values', () async {
      final repository = queryResult.repository!;
      expect(repository.pullRequest, isNotNull);
    });

    test('pullRequest values', () async {
      final pullRequest = queryResult.repository!.pullRequest!;
      expect(pullRequest.author, isNotNull);
      expect(pullRequest.authorAssociation, 'MEMBER');
      expect(pullRequest.commits, isNotNull);
      expect(pullRequest.id, 'PR_kwDOA8VHis43rs4_');
      expect(pullRequest.reviews, isNotNull);
      expect(pullRequest.title, '[dependabot] Remove human reviewers');
      expect(pullRequest.mergeable, MergeableState.MERGEABLE);
    });

    test('Author values', () async {
      final author = queryResult.repository!.pullRequest!.author!;
      expect(author.login, 'author1');
    });

    test('Reviews values', () async {
      final reviews = queryResult.repository!.pullRequest!.reviews!;
      expect(reviews.nodes, isNotNull);
      expect(reviews.nodes!.single, isA<ReviewNode>());
      final review = reviews.nodes!.single;
      expect(review.author, isA<Author>());
      expect(review.authorAssociation, 'MEMBER');
      expect(review.state, 'APPROVED');
    });

    test('Commits values', () async {
      final commits = queryResult.repository!.pullRequest!.commits!;
      expect(commits.nodes, isNotNull);
      final commitNode = commits.nodes!.first;
      expect(commitNode.commit, isNotNull);
      expect(commitNode.commit!.abbreviatedOid, '4009ecc');
      expect(
        commitNode.commit!.oid,
        '4009ecc0b6dbf5cb19cb97472147063e7368ec10',
      );
      expect(
        commitNode.commit!.pushedDate,
        DateTime.parse('2022-05-11 22:35:03.000Z'),
      );
      expect(commitNode.commit!.status, isNotNull);
      final statuses = commitNode.commit!.status!.contexts!;
      expect(statuses[0].createdAt, DateTime.parse('2023-12-01T23:29:12Z'));
    });
  });
}

final Map<String, dynamic> data =
    json.decode(dataString) as Map<String, dynamic>;

const String dataString = '''
{
  "repository": {
    "pullRequest": {
      "author": {
        "login": "author1"
      },
      "authorAssociation": "MEMBER",
      "id": "PR_kwDOA8VHis43rs4_",
      "title": "[dependabot] Remove human reviewers",
      "mergeable": "MERGEABLE",
      "commits": {
        "nodes":[
          {
            "commit": {
              "abbreviatedOid": "4009ecc",
              "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
              "committedDate": "2022-05-11T22:35:02Z",
              "pushedDate": "2022-05-11T22:35:03Z",
              "status": {
                  "contexts": [
                    {
                      "createdAt": "2023-12-01T23:29:12Z",
                      "context": "flutter-gold",
                      "state": "SUCCESS",
                      "targetUrl": "https://flutter-gold.skia.org/cl/github/139397"
                    },
                    {
                      "createdAt": "2023-12-01T22:55:04Z",
                      "context": "tree-status",
                      "state": "SUCCESS",
                      "targetUrl": "https://flutter-dashboard.appspot.com/#/build?repo=flutter"
                    }
                  ]
                }
            }
          }
        ]
      },
      "reviews": {
        "nodes": [
          {
            "author": {
              "login": "keyonghan"
            },
            "authorAssociation": "MEMBER",
            "state": "APPROVED"
          }
        ]
      }
    }
  }
}
''';
