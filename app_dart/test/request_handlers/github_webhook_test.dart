// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';

import 'package:crypto/crypto.dart';
import 'package:github/server.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group('githubWebhookPullRequest', () {
    GithubWebhook webhook;

    MockHttpRequest request;
    MockHttpResponse response;
    MockHttpHeaders headers;
    MockConfig config;
    MockGitHubClient gitHubClient;
    MockIssuesService issuesService;
    MockPullRequestsService pullRequestsService;

    const String keyString = 'not_a_real_key';

    String getHmac(Uint8List list, Uint8List key) {
      final Hmac hmac = Hmac(sha1, key);
      return hmac.convert(list).toString();
    }

    setUp(() {
      request = MockHttpRequest();
      response = MockHttpResponse();
      headers = MockHttpHeaders();
      config = MockConfig();
      gitHubClient = MockGitHubClient();
      issuesService = MockIssuesService();
      pullRequestsService = MockPullRequestsService();

      webhook = GithubWebhook(config);

      when(gitHubClient.issues).thenReturn(issuesService);
      when(gitHubClient.pullRequests).thenReturn(pullRequestsService);

      when(config.nonMasterPullRequestMessage).thenAnswer((_) => Future<String>.value('nonMasterPullRequestMessage'));
      when(config.missingTestsPullRequestMessage)
          .thenAnswer((_) => Future<String>.value('missingTestPullRequestMessage'));
      when(config.githubOAuthToken).thenAnswer((_) => Future<String>.value('githubOAuthKey'));
      when(config.webhookKey).thenAnswer((_) => Future.value(keyString));
      when(config.createGitHubClient()).thenAnswer((_) => Future.value(gitHubClient));

      when(request.response).thenReturn(response);
      when(request.headers).thenReturn(headers);
    });

    tearDown(() {
      verify(response.close()).called(1);
    });

    test('Rejects non-POST methods with methodNotAllowed', () async {
      when(request.method).thenReturn('GET');

      await webhook.service(request);

      verify(response.statusCode = HttpStatus.methodNotAllowed);
    });

    test('Rejects missing headers', () async {
      when(request.method).thenReturn('POST');
      await webhook.service(request);

      verify(response.statusCode = HttpStatus.badRequest);
    });

    test('Rejects invalid hmac', () async {
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      when(headers.value('X-Hub-Signature')).thenReturn('bar');
      request.data = Stream<Uint8List>.fromIterable([utf8.encode('Hello, World!')]);
      await webhook.service(request);

      verify(response.statusCode = HttpStatus.forbidden);
    });

    test('Rejects malformed unicode', () async {
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = Uint8List.fromList([0xc3, 0x28]);
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);
      await webhook.service(request);

      verify(response.statusCode = HttpStatus.badRequest);
    });

    test('Rejects non-json', () async {
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = utf8.encode('Hello, World!');
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);
      await webhook.service(request);

      verify(response.statusCode = HttpStatus.badRequest);
    });

    test('Ignores actions other than open/reopened', () async {
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = utf8.encode(jsonTemplate('closed', 123, 'dev'));
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);
      await webhook.service(request);
      verifyNever(gitHubClient.request(any, any, body: anyNamed('body')));
      verify(response.statusCode = HttpStatus.ok);
    });

    test('Acts on opened against dev', () async {
      const int issueNumber = 123;
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = utf8.encode(jsonTemplate('opened', issueNumber, 'dev'));
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);

      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(gitHubClient.getJSON<List<dynamic>, List<PullRequestFile>>(any, convert: anyNamed('convert'))).thenAnswer(
        (_) => Future.value(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ]),
      );

      await webhook.service(request);

      verify(pullRequestsService.edit(
        slug,
        issueNumber,
        base: 'master',
      )).called(1);

      final String message = await config.nonMasterPullRequestMessage;
      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(message)),
      )).called(1);

      verify(response.statusCode = HttpStatus.ok);
    });

    test('Labels PRs, comment if no tests', () async {
      const int issueNumber = 123;
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = utf8.encode(jsonTemplate('opened', issueNumber, 'master'));
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(gitHubClient.getJSON<List<dynamic>, List<PullRequestFile>>(
        '/repos/${slug.fullName}/pulls/$issueNumber/files',
        convert: anyNamed('convert'),
      )).thenAnswer(
        (_) => Future.value(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ]),
      );

      await webhook.service(request);

      final String message = await config.missingTestsPullRequestMessage;

      verify(gitHubClient.postJSON<List<dynamic>, List<IssueLabel>>(
        '/repos/${slug.fullName}/issues/$issueNumber/labels',
        body: jsonEncode(<String>['framework']),
        convert: anyNamed('convert'),
      )).called(1);
      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(message)),
      )).called(1);
      verify(response.statusCode = HttpStatus.ok);
    });

    test('Labels PRs, no dart files', () async {
      const int issueNumber = 123;
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = utf8.encode(jsonTemplate('opened', issueNumber, 'master'));
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(gitHubClient.getJSON<List<dynamic>, List<PullRequestFile>>(
        '/repos/${slug.fullName}/pulls/$issueNumber/files',
        convert: anyNamed('convert'),
      )).thenAnswer(
        (_) => Future.value(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/blah.md',
        ]),
      );

      await webhook.service(request);

      verify(gitHubClient.postJSON<List<dynamic>, List<IssueLabel>>(
        '/repos/${slug.fullName}/issues/$issueNumber/labels',
        body: jsonEncode(<String>['framework']),
        convert: anyNamed('convert'),
      )).called(1);
      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        any,
      ));
      verify(response.statusCode = HttpStatus.ok);
    });

    test('Labels PRs, no comment if tests', () async {
      const int issueNumber = 123;
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = utf8.encode(jsonTemplate('opened', issueNumber, 'master'));
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(gitHubClient.getJSON<List<dynamic>, List<PullRequestFile>>(
        '/repos/${slug.fullName}/pulls/$issueNumber/files',
        convert: anyNamed('convert'),
      )).thenAnswer(
        (_) => Future.value(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/semantics_test.dart',
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
          PullRequestFile()..filename = 'examples/flutter_gallery/blah.dart',
          PullRequestFile()..filename = 'dev/blah.dart',
          PullRequestFile()..filename = 'bin/internal/engine.version',
          PullRequestFile()..filename = 'packages/flutter/lib/src/cupertino/blah.dart',
          PullRequestFile()..filename = 'packages/flutter/lib/src/material/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_localizations/blah.dart',
        ]),
      );

      await webhook.service(request);

      final String message = await config.missingTestsPullRequestMessage;

      verify(gitHubClient.postJSON<List<dynamic>, List<IssueLabel>>(
        '/repos/${slug.fullName}/issues/$issueNumber/labels',
        body: jsonEncode(<String>[
          'framework',
          'a: accessibility',
          'tool',
          'a: tests',
          'd: examples',
          'team',
          'team: gallery',
          'engine',
          'f: cupertino',
          'f: material design',
          'a: internationalization',
        ]),
        convert: anyNamed('convert'),
      )).called(1);
      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(message)),
      ));
      verify(response.statusCode = HttpStatus.ok);
    });

    test('Skips labeling or commenting on autorolls', () async {
      const int issueNumber = 123;
      when(request.method).thenReturn('POST');
      when(headers.value('X-GitHub-Event')).thenReturn('pull_request');
      final Uint8List body = utf8.encode(jsonTemplate(
        'opened',
        issueNumber,
        'master',
        login: 'engine-flutter-autoroll',
      ));
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      when(headers.value('X-Hub-Signature')).thenReturn('sha1=$hmac');
      request.data = Stream<Uint8List>.fromIterable([body]);

      await webhook.service(request);

      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      verifyNever(gitHubClient.postJSON<List<dynamic>, List<IssueLabel>>(
        '/repos/${slug.fullName}/issues/$issueNumber/labels',
        body: anyNamed('body'),
        convert: anyNamed('convert'),
      ));
      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        any,
      ));
      verify(response.statusCode = HttpStatus.ok);
    });
  });
}

class MockHttpRequest extends Mock implements HttpRequest {
  Stream<Uint8List> data;

  @override
  Stream<S> expand<S>(Iterable<S> convert(Uint8List element)) => data.expand(convert);
}

class MockHttpResponse extends Mock implements HttpResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

// ignore: must_be_immutable
class MockConfig extends Mock implements Config {}

class MockGitHubClient extends Mock implements GitHub {}

class MockIssuesService extends Mock implements IssuesService {}

class MockPullRequestsService extends Mock implements PullRequestsService {}

String jsonTemplate(String action, int number, String baseRef, {String login = 'flutter'}) => '''{
  "action": "$action",
  "number": $number,
  "pull_request": {
    "url": "https://api.github.com/repos/flutter/flutter/pulls/$number",
    "id": 294034,
    "node_id": "MDExOlB1bGxSZXF1ZXN0Mjk0MDMzODQx",
    "html_url": "https://github.com/flutter/flutter/pull/$number",
    "diff_url": "https://github.com/flutter/flutter/pull/$number.diff",
    "patch_url": "https://github.com/flutter/flutter/pull/$number.patch",
    "issue_url": "https://api.github.com/repos/flutter/flutter/issues/$number",
    "number": $number,
    "state": "open",
    "locked": false,
    "title": "Defer reassemble until reload is finished",
    "user": {
      "login": "$login",
      "id": 862741,
      "node_id": "MDQ6VXNlcjg2MjA3NDE=",
      "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/flutter",
      "html_url": "https://github.com/flutter",
      "followers_url": "https://api.github.com/users/flutter/followers",
      "following_url": "https://api.github.com/users/flutter/following{/other_user}",
      "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
      "organizations_url": "https://api.github.com/users/flutter/orgs",
      "repos_url": "https://api.github.com/users/flutter/repos",
      "events_url": "https://api.github.com/users/flutter/events{/privacy}",
      "received_events_url": "https://api.github.com/users/flutter/received_events",
      "type": "User",
      "site_admin": false
    },
    "body": "The body",
    "created_at": "2019-07-03T07:14:35Z",
    "updated_at": "2019-07-03T16:34:53Z",
    "closed_at": null,
    "merged_at": null,
    "merge_commit_sha": "d22ab7ced21d3b2a5be00cf576d383eb5ffddb8a",
    "assignee": null,
    "assignees": [],
    "requested_reviewers": [],
    "requested_teams": [],
    "labels": [
      {
        "id": 487496476,
        "node_id": "MDU6TGFiZWw0ODc0OTY0NzY=",
        "url": "https://api.github.com/repos/flutter/flutter/labels/cla:%20yes",
        "name": "cla: yes",
        "color": "ffffff",
        "default": false
      },
      {
        "id": 284437560,
        "node_id": "MDU6TGFiZWwyODQ0Mzc1NjA=",
        "url": "https://api.github.com/repos/flutter/flutter/labels/framework",
        "name": "framework",
        "color": "207de5",
        "default": false
      },
      {
        "id": 283480100,
        "node_id": "MDU6TGFiZWwyODM0ODAxMDA=",
        "url": "https://api.github.com/repos/flutter/flutter/labels/tool",
        "name": "tool",
        "color": "5319e7",
        "default": false
      }
    ],
    "milestone": null,
    "commits_url": "https://api.github.com/repos/flutter/flutter/pulls/$number/commits",
    "review_comments_url": "https://api.github.com/repos/flutter/flutter/pulls/$number/comments",
    "review_comment_url": "https://api.github.com/repos/flutter/flutter/pulls/comments{/number}",
    "comments_url": "https://api.github.com/repos/flutter/flutter/issues/$number/comments",
    "statuses_url": "https://api.github.com/repos/flutter/flutter/statuses/be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
    "head": {
      "label": "$login:wait_for_reassemble",
      "ref": "wait_for_reassemble",
      "sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "user": {
        "login": "$login",
        "id": 8620741,
        "node_id": "MDQ6VXNlcjg2MjA3NDE=",
        "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "followers_url": "https://api.github.com/users/flutter/followers",
        "following_url": "https://api.github.com/users/flutter/following{/other_user}",
        "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
        "organizations_url": "https://api.github.com/users/flutter/orgs",
        "repos_url": "https://api.github.com/users/flutter/repos",
        "events_url": "https://api.github.com/users/flutter/events{/privacy}",
        "received_events_url": "https://api.github.com/users/flutter/received_events",
        "type": "User",
        "site_admin": false
      },
      "repo": {
        "id": 131232406,
        "node_id": "MDEwOlJlcG9zaXRvcnkxMzEyMzI0MDY=",
        "name": "flutter",
        "full_name": "flutter/flutter",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 8620741,
          "node_id": "MDQ6VXNlcjg2MjA3NDE=",
          "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
          "gravatar_id": "",
          "url": "https://api.github.com/users/flutter",
          "html_url": "https://github.com/flutter",
          "followers_url": "https://api.github.com/users/flutter/followers",
          "following_url": "https://api.github.com/users/flutter/following{/other_user}",
          "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
          "organizations_url": "https://api.github.com/users/flutter/orgs",
          "repos_url": "https://api.github.com/users/flutter/repos",
          "events_url": "https://api.github.com/users/flutter/events{/privacy}",
          "received_events_url": "https://api.github.com/users/flutter/received_events",
          "type": "User",
          "site_admin": false
        },
        "html_url": "https://github.com/flutter/flutter",
        "description": "Flutter makes it easy and fast to build beautiful mobile apps.",
        "fork": true,
        "url": "https://api.github.com/repos/flutter/flutter",
        "forks_url": "https://api.github.com/repos/flutter/flutter/forks",
        "keys_url": "https://api.github.com/repos/flutter/flutter/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/flutter/flutter/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/flutter/flutter/teams",
        "hooks_url": "https://api.github.com/repos/flutter/flutter/hooks",
        "issue_events_url": "https://api.github.com/repos/flutter/flutter/issues/events{/number}",
        "events_url": "https://api.github.com/repos/flutter/flutter/events",
        "assignees_url": "https://api.github.com/repos/flutter/flutter/assignees{/user}",
        "branches_url": "https://api.github.com/repos/flutter/flutter/branches{/branch}",
        "tags_url": "https://api.github.com/repos/flutter/flutter/tags",
        "blobs_url": "https://api.github.com/repos/flutter/flutter/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/flutter/flutter/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/flutter/flutter/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/flutter/flutter/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/flutter/flutter/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/flutter/flutter/languages",
        "stargazers_url": "https://api.github.com/repos/flutter/flutter/stargazers",
        "contributors_url": "https://api.github.com/repos/flutter/flutter/contributors",
        "subscribers_url": "https://api.github.com/repos/flutter/flutter/subscribers",
        "subscription_url": "https://api.github.com/repos/flutter/flutter/subscription",
        "commits_url": "https://api.github.com/repos/flutter/flutter/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/flutter/flutter/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/flutter/flutter/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/flutter/flutter/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/flutter/flutter/contents/{+path}",
        "compare_url": "https://api.github.com/repos/flutter/flutter/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/flutter/flutter/merges",
        "archive_url": "https://api.github.com/repos/flutter/flutter/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/flutter/flutter/downloads",
        "issues_url": "https://api.github.com/repos/flutter/flutter/issues{/number}",
        "pulls_url": "https://api.github.com/repos/flutter/flutter/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/flutter/flutter/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/flutter/flutter/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/flutter/flutter/labels{/name}",
        "releases_url": "https://api.github.com/repos/flutter/flutter/releases{/id}",
        "deployments_url": "https://api.github.com/repos/flutter/flutter/deployments",
        "created_at": "2018-04-27T02:03:08Z",
        "updated_at": "2019-06-27T06:56:59Z",
        "pushed_at": "2019-07-03T19:40:11Z",
        "git_url": "git://github.com/flutter/flutter.git",
        "ssh_url": "git@github.com:flutter/flutter.git",
        "clone_url": "https://github.com/flutter/flutter.git",
        "svn_url": "https://github.com/flutter/flutter",
        "homepage": "https://flutter.io",
        "size": 94508,
        "stargazers_count": 1,
        "watchers_count": 1,
        "language": "Dart",
        "has_issues": false,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 0,
        "license": {
          "key": "other",
          "name": "Other",
          "spdx_id": "NOASSERTION",
          "url": null,
          "node_id": "MDc6TGljZW5zZTA="
        },
        "forks": 0,
        "open_issues": 0,
        "watchers": 1,
        "default_branch": "master"
      }
    },
    "base": {
      "label": "flutter:$baseRef",
      "ref": "$baseRef",
      "sha": "4cd12fc8b7d4cc2d8609182e1c4dea5cddc86890",
      "user": {
        "login": "flutter",
        "id": 14101776,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
        "avatar_url": "https://avatars3.githubblahblahblah",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "followers_url": "https://api.github.com/users/flutter/followers",
        "following_url": "https://api.github.com/users/flutter/following{/other_user}",
        "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
        "organizations_url": "https://api.github.com/users/flutter/orgs",
        "repos_url": "https://api.github.com/users/flutter/repos",
        "events_url": "https://api.github.com/users/flutter/events{/privacy}",
        "received_events_url": "https://api.github.com/users/flutter/received_events",
        "type": "Organization",
        "site_admin": false
      },
      "repo": {
        "id": 31792824,
        "node_id": "MDEwOlJlcG9zaXRvcnkzMTc5MjgyNA==",
        "name": "flutter",
        "full_name": "flutter/flutter",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 14101776,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
          "avatar_url": "https://avatars3.githubblahblahblah",
          "gravatar_id": "",
          "url": "https://api.github.com/users/flutter",
          "html_url": "https://github.com/flutter",
          "followers_url": "https://api.github.com/users/flutter/followers",
          "following_url": "https://api.github.com/users/flutter/following{/other_user}",
          "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
          "organizations_url": "https://api.github.com/users/flutter/orgs",
          "repos_url": "https://api.github.com/users/flutter/repos",
          "events_url": "https://api.github.com/users/flutter/events{/privacy}",
          "received_events_url": "https://api.github.com/users/flutter/received_events",
          "type": "Organization",
          "site_admin": false
        },
        "html_url": "https://github.com/flutter/flutter",
        "description": "Flutter makes it easy and fast to build beautiful mobile apps.",
        "fork": false,
        "url": "https://api.github.com/repos/flutter/flutter",
        "forks_url": "https://api.github.com/repos/flutter/flutter/forks",
        "keys_url": "https://api.github.com/repos/flutter/flutter/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/flutter/flutter/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/flutter/flutter/teams",
        "hooks_url": "https://api.github.com/repos/flutter/flutter/hooks",
        "issue_events_url": "https://api.github.com/repos/flutter/flutter/issues/events{/number}",
        "events_url": "https://api.github.com/repos/flutter/flutter/events",
        "assignees_url": "https://api.github.com/repos/flutter/flutter/assignees{/user}",
        "branches_url": "https://api.github.com/repos/flutter/flutter/branches{/branch}",
        "tags_url": "https://api.github.com/repos/flutter/flutter/tags",
        "blobs_url": "https://api.github.com/repos/flutter/flutter/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/flutter/flutter/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/flutter/flutter/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/flutter/flutter/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/flutter/flutter/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/flutter/flutter/languages",
        "stargazers_url": "https://api.github.com/repos/flutter/flutter/stargazers",
        "contributors_url": "https://api.github.com/repos/flutter/flutter/contributors",
        "subscribers_url": "https://api.github.com/repos/flutter/flutter/subscribers",
        "subscription_url": "https://api.github.com/repos/flutter/flutter/subscription",
        "commits_url": "https://api.github.com/repos/flutter/flutter/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/flutter/flutter/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/flutter/flutter/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/flutter/flutter/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/flutter/flutter/contents/{+path}",
        "compare_url": "https://api.github.com/repos/flutter/flutter/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/flutter/flutter/merges",
        "archive_url": "https://api.github.com/repos/flutter/flutter/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/flutter/flutter/downloads",
        "issues_url": "https://api.github.com/repos/flutter/flutter/issues{/number}",
        "pulls_url": "https://api.github.com/repos/flutter/flutter/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/flutter/flutter/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/flutter/flutter/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/flutter/flutter/labels{/name}",
        "releases_url": "https://api.github.com/repos/flutter/flutter/releases{/id}",
        "deployments_url": "https://api.github.com/repos/flutter/flutter/deployments",
        "created_at": "2015-03-06T22:54:58Z",
        "updated_at": "2019-07-04T02:08:44Z",
        "pushed_at": "2019-07-04T02:03:04Z",
        "git_url": "git://github.com/flutter/flutter.git",
        "ssh_url": "git@github.com:flutter/flutter.git",
        "clone_url": "https://github.com/flutter/flutter.git",
        "svn_url": "https://github.com/flutter/flutter",
        "homepage": "https://flutter.dev",
        "size": 65507,
        "stargazers_count": 68944,
        "watchers_count": 68944,
        "language": "Dart",
        "has_issues": true,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 7987,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 6536,
        "license": {
          "key": "other",
          "name": "Other",
          "spdx_id": "NOASSERTION",
          "url": null,
          "node_id": "MDc6TGljZW5zZTA="
        },
        "forks": 7987,
        "open_issues": 6536,
        "watchers": 68944,
        "default_branch": "master"
      }
    },
    "_links": {
      "self": {
        "href": "https://api.github.com/repos/flutter/flutter/pulls/$number"
      },
      "html": {
        "href": "https://github.com/flutter/flutter/pull/$number"
      },
      "issue": {
        "href": "https://api.github.com/repos/flutter/flutter/issues/$number"
      },
      "comments": {
        "href": "https://api.github.com/repos/flutter/flutter/issues/$number/comments"
      },
      "review_comments": {
        "href": "https://api.github.com/repos/flutter/flutter/pulls/$number/comments"
      },
      "review_comment": {
        "href": "https://api.github.com/repos/flutter/flutter/pulls/comments{/number}"
      },
      "commits": {
        "href": "https://api.github.com/repos/flutter/flutter/pulls/$number/commits"
      },
      "statuses": {
        "href": "https://api.github.com/repos/flutter/flutter/statuses/deadbeef"
      }
    },
    "author_association": "MEMBER",
    "merged": false,
    "mergeable": true,
    "rebaseable": true,
    "mergeable_state": "draft",
    "merged_by": null,
    "comments": 1,
    "review_comments": 0,
    "maintainer_can_modify": true,
    "commits": 5,
    "additions": 55,
    "deletions": 36,
    "changed_files": 5
  },
  "repository": {
    "id": 1868532,
    "node_id": "MDEwOlJlcG9zaXRvcnkxODY4NTMwMDI=",
    "name": "flutter",
    "full_name": "flutter/flutter",
    "private": false,
    "owner": {
      "login": "flutter",
      "id": 21031067,
      "node_id": "MDQ6VXNlcjIxMDMxMDY3",
      "avatar_url": "https://avatars1.githubusercontent.com/u/21031067?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/flutter",
      "html_url": "https://github.com/flutter",
      "followers_url": "https://api.github.com/users/flutter/followers",
      "following_url": "https://api.github.com/users/flutter/following{/other_user}",
      "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
      "organizations_url": "https://api.github.com/users/flutter/orgs",
      "repos_url": "https://api.github.com/users/flutter/repos",
      "events_url": "https://api.github.com/users/flutter/events{/privacy}",
      "received_events_url": "https://api.github.com/users/flutter/received_events",
      "type": "User",
      "site_admin": false
    },
    "html_url": "https://github.com/flutter/flutter",
    "description": null,
    "fork": false,
    "url": "https://api.github.com/repos/flutter/flutter",
    "forks_url": "https://api.github.com/repos/flutter/flutter/forks",
    "keys_url": "https://api.github.com/repos/flutter/flutter/keys{/key_id}",
    "collaborators_url": "https://api.github.com/repos/flutter/flutter/collaborators{/collaborator}",
    "teams_url": "https://api.github.com/repos/flutter/flutter/teams",
    "hooks_url": "https://api.github.com/repos/flutter/flutter/hooks",
    "issue_events_url": "https://api.github.com/repos/flutter/flutter/issues/events{/number}",
    "events_url": "https://api.github.com/repos/flutter/flutter/events",
    "assignees_url": "https://api.github.com/repos/flutter/flutter/assignees{/user}",
    "branches_url": "https://api.github.com/repos/flutter/flutter/branches{/branch}",
    "tags_url": "https://api.github.com/repos/flutter/flutter/tags",
    "blobs_url": "https://api.github.com/repos/flutter/flutter/git/blobs{/sha}",
    "git_tags_url": "https://api.github.com/repos/flutter/flutter/git/tags{/sha}",
    "git_refs_url": "https://api.github.com/repos/flutter/flutter/git/refs{/sha}",
    "trees_url": "https://api.github.com/repos/flutter/flutter/git/trees{/sha}",
    "statuses_url": "https://api.github.com/repos/flutter/flutter/statuses/{sha}",
    "languages_url": "https://api.github.com/repos/flutter/flutter/languages",
    "stargazers_url": "https://api.github.com/repos/flutter/flutter/stargazers",
    "contributors_url": "https://api.github.com/repos/flutter/flutter/contributors",
    "subscribers_url": "https://api.github.com/repos/flutter/flutter/subscribers",
    "subscription_url": "https://api.github.com/repos/flutter/flutter/subscription",
    "commits_url": "https://api.github.com/repos/flutter/flutter/commits{/sha}",
    "git_commits_url": "https://api.github.com/repos/flutter/flutter/git/commits{/sha}",
    "comments_url": "https://api.github.com/repos/flutter/flutter/comments{/number}",
    "issue_comment_url": "https://api.github.com/repos/flutter/flutter/issues/comments{/number}",
    "contents_url": "https://api.github.com/repos/flutter/flutter/contents/{+path}",
    "compare_url": "https://api.github.com/repos/flutter/flutter/compare/{base}...{head}",
    "merges_url": "https://api.github.com/repos/flutter/flutter/merges",
    "archive_url": "https://api.github.com/repos/flutter/flutter/{archive_format}{/ref}",
    "downloads_url": "https://api.github.com/repos/flutter/flutter/downloads",
    "issues_url": "https://api.github.com/repos/flutter/flutter/issues{/number}",
    "pulls_url": "https://api.github.com/repos/flutter/flutter/pulls{/number}",
    "milestones_url": "https://api.github.com/repos/flutter/flutter/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/flutter/flutter/notifications{?since,all,participating}",
    "labels_url": "https://api.github.com/repos/flutter/flutter/labels{/name}",
    "releases_url": "https://api.github.com/repos/flutter/flutter/releases{/id}",
    "deployments_url": "https://api.github.com/repos/flutter/flutter/deployments",
    "created_at": "2019-05-15T15:19:25Z",
    "updated_at": "2019-05-15T15:19:27Z",
    "pushed_at": "2019-05-15T15:20:32Z",
    "git_url": "git://github.com/flutter/flutter.git",
    "ssh_url": "git@github.com:flutter/flutter.git",
    "clone_url": "https://github.com/flutter/flutter.git",
    "svn_url": "https://github.com/flutter/flutter",
    "homepage": null,
    "size": 0,
    "stargazers_count": 0,
    "watchers_count": 0,
    "language": null,
    "has_issues": true,
    "has_projects": true,
    "has_downloads": true,
    "has_wiki": true,
    "has_pages": true,
    "forks_count": 0,
    "mirror_url": null,
    "archived": false,
    "disabled": false,
    "open_issues_count": 2,
    "license": null,
    "forks": 0,
    "open_issues": 2,
    "watchers": 0,
    "default_branch": "master"
  },
  "sender": {
    "login": "$login",
    "id": 21031067,
    "node_id": "MDQ6VXNlcjIxMDMxMDY3",
    "avatar_url": "https://avatars1.githubusercontent.com/u/21031067?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/flutter",
    "html_url": "https://github.com/flutter",
    "followers_url": "https://api.github.com/users/flutter/followers",
    "following_url": "https://api.github.com/users/flutter/following{/other_user}",
    "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
    "organizations_url": "https://api.github.com/users/flutter/orgs",
    "repos_url": "https://api.github.com/users/flutter/repos",
    "events_url": "https://api.github.com/users/flutter/events{/privacy}",
    "received_events_url": "https://api.github.com/users/flutter/received_events",
    "type": "User",
    "site_admin": false
  }
}''';
