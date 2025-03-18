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
  late RevertPullRequestData revertPullRequestData;

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

  group('Revert pull request models', () {
    setUp(() {
      revertPullRequestData = RevertPullRequestData.fromJson(revertData);
    });

    test('All fields are present', () {
      expect(revertPullRequestData.revertPullRequest, isNotNull);
      expect(
        revertPullRequestData.revertPullRequest!.clientMutationId,
        isNotNull,
      );
      expect(revertPullRequestData.revertPullRequest!.pullRequest, isNotNull);
      expect(
        revertPullRequestData.revertPullRequest!.revertPullRequest,
        isNotNull,
      );
    });

    test('Client Mutation Id field', () {
      expect(
        revertPullRequestData.revertPullRequest!.clientMutationId,
        'ra186026',
      );
    });

    test('To be reverted PullRequest field.', () {
      final pullRequest = revertPullRequestData.revertPullRequest!.pullRequest!;
      expect(pullRequest.id, 'PR_kwDOIRxr_M5MQ7mV');
      expect(
        pullRequest.title,
        'Adding a TODO comment for testing pull request auto approval.',
      );
      expect(pullRequest.author!.login, 'ricardoamador');
      expect(
        pullRequest.body,
        'This is for testing revert and should be present in the revert mutation.',
      );
    });

    test('Revert PullRequest field.', () {
      final revertPullRequest =
          revertPullRequestData.revertPullRequest!.revertPullRequest!;
      expect(revertPullRequest.id, 'PR_kwDOIRxr_M5QN0kD');
      expect(revertPullRequest.title, 'Revert comment in configuration file.');
      expect(revertPullRequest.author!.login, 'ricardoamador');
      expect(revertPullRequest.body, 'Testing revert mutation');
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

final Map<String, dynamic> revertData =
    json.decode(revertRequestString) as Map<String, dynamic>;

const String revertRequestString = '''
{
   "revertPullRequest": {
      "clientMutationId": "ra186026",
      "pullRequest": {
        "author": {
          "login": "ricardoamador"
        },
        "authorAssociation": "OWNER",
        "id": "PR_kwDOIRxr_M5MQ7mV",
        "title": "Adding a TODO comment for testing pull request auto approval.",
        "number": 18,
        "body": "This is for testing revert and should be present in the revert mutation.",
        "repository": {
          "owner": {
            "login": "ricardoamador"
          },
          "name": "flutter_test"
        }
      },
      "revertPullRequest": {
        "author": {
          "login": "ricardoamador"
        },
        "authorAssociation": "OWNER",
        "id": "PR_kwDOIRxr_M5QN0kD",
        "title": "Revert comment in configuration file.",
        "number": 23,
        "body": "Testing revert mutation",
        "repository": {
          "owner": {
            "login": "ricardoamador"
          },
          "name": "flutter_test"
        }
      }
    }
}
''';
