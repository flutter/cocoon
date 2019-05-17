// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

import 'package:flutter_web/foundation.dart';

import '../models/github_authentication.dart';
import '../models/repository_status.dart';

class GithubService<T extends RepositoryStatus> {
  static Map<Uri, String> _eTagByURL = {}; // Github change token (eTag) by URL. Do not cache URLs like commits that change often.

  static Future<void> fetchRepositoryDetails(RepositoryStatus repositoryStatus) async {
    Map<String, dynamic> fetchedDetails = await _getBody('repos/flutter/${repositoryStatus.name}');
    if (fetchedDetails != null) {
      repositoryStatus
        ..watchersCount = fetchedDetails['watchers']
        ..subscribersCount = fetchedDetails['subscribers_count'];
    }
  }

  static Future<void> fetchRepositoryIssues(RepositoryStatus repositoryStatus) async {
    // Use spaces instead of pluses in Github query parameters. Dart encodes spaces as +, but + is encoded as %2B which Github cannot parse and will think is malformed.
    Uri url = Uri.https('api.github.com', 'search/issues', <String, String>{'q': 'repo:flutter/${repositoryStatus.name} is:open', 'per_page': '100'});
    await _fetchRepositoryIssuesByPage(url, repositoryStatus);
  }

  static Future<void> fetchToDoCount(RepositoryStatus repositoryStatus) async {
    Map<String, dynamic> body = await _getBody('search/code', queryParameters: <String, String>{'q': 'repo:flutter/${repositoryStatus.name} TODO', 'per_page': '1', 'page': '0'});
    if (body != null) {
      repositoryStatus.todoCount = body['total_count'];
    }
  }

  static Future<DateTime> fetchFlutterBranchLastCommitDate(String branchName) async {
    Map<String, dynamic> body = await _getBody('repos/flutter/flutter/branches/$branchName');
    return (body == null) ? null : DateTime.tryParse(body['commit']['commit']['committer']['date']);
  }

  static Future<DateTime> lastCommitFromAuthor(String repositoryName, String author) async {
    List<dynamic> body = await _getBody('repos/flutter/$repositoryName/commits', queryParameters: <String, String>{'author': author, 'per_page': '1'});
    return (body == null) ? null : DateTime.tryParse(body[0]['commit']['committer']['date']);
  }

  static Future<void> _fetchRepositoryIssuesByPage(Uri url, RepositoryStatus repositoryStatus) async {
    HttpRequest response = await _getResponse(url);
    if (response == null) {
      return;
    }
    String body = response.response;
    if (body == null || body.isEmpty) {
      return;
    }
    Map<String, dynamic> fetchedDetails = jsonDecode(body);
    List<dynamic> issues = fetchedDetails['items'];

    for (Map<String, dynamic> issue in issues) {
      if (issue['pull_request'] != null) {
        _processPullRequest(issue, repositoryStatus);
      } else {
        _processIssue(issue, repositoryStatus);
      }
      // Include labels from both PRs and issues.
      _processLabels(issue, repositoryStatus);
    }

    Uri nextPageUrl = _nextSearchPageURLFromHeaders(response.responseHeaders);
    if (nextPageUrl != null) {
      await _fetchRepositoryIssuesByPage(nextPageUrl, repositoryStatus);
    }
  }

  static Uri _nextSearchPageURLFromHeaders(Map<String, String> responseHeaders) {
    String linkHeader = responseHeaders['link'];
    if (linkHeader == null) {
      return null;
    }
    List<String> links = linkHeader.split(',');
    int index = links.indexWhere((link) => link.contains('rel="next"'));
    if (index == -1) {
      return null;
    }
    String link = links[index];
    int start = link.indexOf('<') + 1;
    int end = link.indexOf('>');
    String nextPageUrlString = link.substring(start, end);
    return Uri.parse(nextPageUrlString);
  }

  static void _processPullRequest(Map<String, dynamic> pullRequest, RepositoryStatus repositoryStatus) {
    repositoryStatus.pullRequestCount += 1;
    DateTime createdAt = DateTime.tryParse(pullRequest['created_at']);
    if (createdAt != null) {
      repositoryStatus.totalAgeOfAllPullRequests += DateTime.now().difference(createdAt).inDays;
    }

    DateTime updatedAt = DateTime.tryParse(pullRequest['updated_at']);
    if (updatedAt != null && DateTime.now().difference(updatedAt).inDays >= RepositoryStatus.stalePullRequestThresholdInDays) {
      repositoryStatus.stalePullRequestCount += 1;
    }
    String title = pullRequest['title'];
    if (title.startsWith('[')) {
      int end = title.indexOf(']');
      if (end != -1) {
        String titleTopic = title.substring(1, end);
        if (titleTopic.isNotEmpty) {
          repositoryStatus
            ..pullRequestCountByTitleTopic.putIfAbsent(titleTopic, () => 0)
            ..pullRequestCountByTitleTopic[titleTopic] += 1;
        }
      }
    }
  }

  static void _processIssue(Map<String, dynamic> issue, RepositoryStatus repositoryStatus) {
    repositoryStatus.issueCount += 1;

    var milestone = issue['milestone'];
    if (milestone == null) {
      repositoryStatus.missingMilestoneIssuesCount += 1;
    }
    DateTime createdAt = DateTime.tryParse(issue['created_at']);
    if (createdAt != null) {
      repositoryStatus.totalAgeOfAllIssues += DateTime.now().difference(createdAt).inDays;
    }

    DateTime updatedAt = DateTime.tryParse(issue['updated_at']);
    if (updatedAt != null && DateTime.now().difference(updatedAt).inDays >= RepositoryStatus.staleIssueThresholdInDays) {
      repositoryStatus.staleIssueCount += 1;
    }
  }

  static _processLabels(Map<String, dynamic> issue, RepositoryStatus repositoryStatus) {
    List<dynamic> labelNames = issue['labels'].map((issue) => issue['name']).toList();
    for (String labelName in labelNames) {
      repositoryStatus
        ..issueCountByLabelName.putIfAbsent(labelName, () => 0)
        ..issueCountByLabelName[labelName] += 1;
    }
  }

  static Future<HttpRequest> _getResponse(Uri url) async {
    Map<String, String> headers = {};

    GithubAuthentication githubAuthentication = GithubAuthentication();
    if (githubAuthentication.isSignedIntoGithub) {
      headers['Authorization'] = 'token ${githubAuthentication.token}';
    }

    String requestETag = _eTagByURL[url];
    if (requestETag != null) {
      headers['If-None-Match'] = requestETag;
    }

    HttpRequest response = await HttpRequest.request(url.toString(), requestHeaders: headers);

    if (response?.status == HttpStatus.notModified) {
      debugPrint('Github reports query results have not been updated since last check of "${url}", skipping.');
    }

    String responseETag = response?.responseHeaders['etag'];
    if (responseETag != null) {
      _eTagByURL[url] = responseETag;
    }
    return response;
  }

  static Future<dynamic> _getBody(String path, {Map<String, String> queryParameters}) async {
    Uri url = Uri.https('api.github.com', path, queryParameters);
    HttpRequest response = await _getResponse(url);
    String body = response?.response;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  }
}
