// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/public_api_request_handler.dart';

/// Request handler to get a list of suppressed tests.
///
/// GET /api/public/suppressed-tests
///
/// Parameters:
///   repo: (string in query) default: 'flutter/flutter'. Name of the repo.
///
/// Response:
/// [
///   {
///     "name": "foo_test",
///     "repository": "flutter/flutter",
///     "issueLink": "...",
///     "createTimestamp": 123456789,
///     "updates": [
///       {
///         "updateTimestamp": 123456789,
///         "note": "...",
///         "user": "..."
///         "action": "SUPPRESS" or "UNSUPPRESS"
///       }
///     ]
///   }
/// ]
@immutable
final class GetSuppressedTests extends PublicApiRequestHandler {
  const GetSuppressedTests({required super.config, required this.firestore});

  final FirestoreService firestore;

  static const String kRepoParam = 'repo';

  @override
  Future<Response> get(Request request) async {
    if (!config.flags.dynamicTestSuppression) {
      return Response.json([]);
    }

    final repoName =
        request.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.fullName;
    final slug = RepositorySlug.full(repoName);

    final suppressedTests = await SuppressedTest.getSuppressedTests(
      firestore,
      slug.fullName,
    );

    return Response.json([
      for (final test in suppressedTests)
        {
          'name': test.testName,
          'repository': test.repository,
          'issueLink': test.issueLink,
          'createTimestamp': test.createTimestamp.millisecondsSinceEpoch,
          'updates': [
            for (var update in test.updates)
              {
                'user': update['user'],
                'action': update['action'],
                'note': update['note'],
                'updateTimestamp':
                    update['updateTimestamp'].millisecondsSinceEpoch,
              },
          ],
        },
    ]);
  }
}
