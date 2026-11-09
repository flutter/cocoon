// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/github/pull_request_review.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('PullRequestReviewEvent', () {
    test(
      'deserializes and serializes pull_request_review payload accurately',
      () {
        const payloadJson = '''
{
  "action": "submitted",
  "review": {
    "id": 88812345,
    "user": {
      "login": "octocat",
      "id": 1
    },
    "body": "LGTM!",
    "state": "APPROVED",
    "html_url": "https://github.com/flutter/flutter/pull/100#pullrequestreview-88812345",
    "commit_id": "abc123def456"
  },
  "pull_request": {
    "number": 100,
    "state": "open",
    "title": "Fix something important",
    "head": {
      "sha": "abc123def456"
    }
  },
  "repository": {
    "name": "flutter",
    "full_name": "flutter/flutter"
  },
  "sender": {
    "login": "octocat",
    "id": 1
  }
}
''';

        final parsedJson = jsonDecode(payloadJson) as Map<String, dynamic>;
        final event = PullRequestReviewEvent.fromJson(parsedJson);

        expect(event.action, 'submitted');
        expect(event.review, isNotNull);
        expect(event.review!.id, 88812345);
        expect(event.review!.user?.login, 'octocat');
        expect(event.review!.body, 'LGTM!');
        expect(event.review!.state, 'APPROVED');
        expect(event.review!.commitId, 'abc123def456');

        expect(event.pullRequest, isNotNull);
        expect(event.pullRequest!.number, 100);
        expect(event.pullRequest!.head?.sha, 'abc123def456');

        expect(event.repository, isNotNull);
        expect(event.repository!.fullName, 'flutter/flutter');

        expect(event.sender, isNotNull);
        expect(event.sender!.login, 'octocat');

        // Roundtrip toJson
        final serialized = event.toJson();
        expect(serialized['action'], 'submitted');
        expect(serialized['review'], isNotNull);
        expect(serialized['pull_request'], isNotNull);

        // Verify toString contains class name and details
        expect(event.toString(), contains('PullRequestReviewEvent'));
        expect(event.toString(), contains('submitted'));
      },
    );
  });
}
