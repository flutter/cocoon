// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;
import 'dart:convert';
import 'dart:html';

import 'package:flutter_web/foundation.dart';
import 'package:intl/intl.dart';

import '../models/github_authentication.dart';
import '../models/repository_status.dart';

Map<Uri, String> _eTagByURL = <Uri, String>{}; // Github change token (eTag) by URL.

Future<void> fetchRepositoryDetails(RepositoryStatus repositoryStatus) async {
  final Map<String, dynamic> fetchedDetails = await _getBody('repos/flutter/${repositoryStatus.name}');
  if (fetchedDetails != null) {
    repositoryStatus
      ..watchersCount = fetchedDetails['watchers']
      ..subscribersCount = fetchedDetails['subscribers_count']
      ..issuesEnabled = fetchedDetails['has_issues'];
  }
}

Future<int> fetchToDoCount(String repositoryName) async {
  final Map<String, dynamic> body = await _getBody('search/code', queryParameters: <String, String>{'q': 'repo:flutter/${repositoryName} TODO', 'per_page': '1', 'page': '0'});
  return (body == null) ? null : body['total_count'];
}

Future<DateTime> fetchBranchLastCommitDate(String repositoryName, String branchName) async {
  final Map<String, dynamic> body = await _getBody('repos/flutter/$repositoryName/branches/$branchName');
  return (body == null) ? null : DateTime.tryParse(body['commit']['commit']['committer']['date']);
}

Future<DateTime> lastCommitFromAuthor(String repositoryName, String author) async {
  final List<dynamic> body = await _getBody('repos/flutter/$repositoryName/commits', queryParameters: <String, String>{'author': author, 'per_page': '1'});
  return (body == null) ? null : DateTime.tryParse(body[0]['commit']['committer']['date']);
}

Future<int> fetchIssueCount(String repositoryName) async {
  return _searchIssuesTotalCount(repositoryName);
}

Future<int> fetchStaleIssueCount(String repositoryName) async {
  final DateTime staleDate = DateTime.now().subtract(Duration(days: RepositoryStatus.staleIssueThresholdInDays));
  final String stateDateQuery = DateFormat('yyyy-MM-dd').format(staleDate);
  return _searchIssuesTotalCount(repositoryName, additionalQuery: 'updated:<=$stateDateQuery');
}

Future<int> fetchIssuesWithoutMilestone(String repositoryName) async {
  return _searchIssuesTotalCount(repositoryName, additionalQuery: 'no:milestone');
}

Future<int>_searchIssuesTotalCount(String repositoryName, {String additionalQuery = ''}) async {
  final Map<String, dynamic> body = await _getBody('search/issues', queryParameters: <String, String>{'q': 'repo:flutter/${repositoryName} is:open is:issue $additionalQuery', 'page': '0', 'per_page': '1'});
  return (body == null) ? null : body['total_count'];
}

Future<void> fetchPullRequests(RepositoryStatus repositoryStatus) async {
  final Map<String, int> pullRequestCountByTopicAggregator = {};
  final Map<String, int> pullRequestCountByLabelAggregator = {};

  // Reset counters to be aggregated in _fetchRepositoryPullRequestsByPage.
  repositoryStatus.pullRequestCount = 0;
  repositoryStatus.totalAgeOfAllPullRequests = 0;

  // Use spaces instead of pluses in Github query parameters. Dart encodes spaces as +, but + is encoded as %2B which Github cannot parse and will think is malformed.
  final Uri pullRequestUrl = Uri.https('api.github.com', 'search/issues', <String, String>{'q': 'repo:flutter/${repositoryStatus.name} is:open is:pr', 'per_page': '100'});
  await _fetchRepositoryPullRequestsByPage(pullRequestUrl, repositoryStatus, pullRequestCountByLabelAggregator, pullRequestCountByTopicAggregator);

  // SplayTreeMap doesn't allow sorting by value (count) on insert. Sort at the end once all search page fetches are complete.
  repositoryStatus.pullRequestCountByLabelName = _sortTopics(pullRequestCountByLabelAggregator);
  repositoryStatus.pullRequestCountByTitleTopic = _sortTopics(pullRequestCountByTopicAggregator);
}

Future<void> _fetchRepositoryPullRequestsByPage(Uri url, RepositoryStatus repositoryStatus, Map<String, int> pullRequestCountByLabelAggregator, Map<String, int> pullRequestCountByTopicAggregator) async {
  final HttpRequest response = await _getResponse(url);
  if (response == null) {
    return;
  }
  final String body = response.response;
  if (body == null || body.isEmpty) {
    return;
  }
  final Map<String, dynamic> fetchedDetails = jsonDecode(body);
  final List<dynamic> issues = fetchedDetails['items'];

  for (Map<String, dynamic> issue in issues) {
    _processPullRequest(issue, repositoryStatus, pullRequestCountByTopicAggregator);
    _processLabels(issue, pullRequestCountByLabelAggregator);
  }

  final Uri nextPageUrl = _nextSearchPageURLFromHeaders(response.responseHeaders);
  if (nextPageUrl != null) {
    await _fetchRepositoryPullRequestsByPage(nextPageUrl, repositoryStatus, pullRequestCountByLabelAggregator, pullRequestCountByTopicAggregator);
  }
}

SplayTreeMap<String, int> _sortTopics(Map<String, int> previousTopics) {
  return SplayTreeMap<String, int>.of(previousTopics, (String a, String b) {
    // Sort by count, descending.
    final int aValue = previousTopics[a];
    final int bValue = previousTopics[b];
    if (bValue > aValue) {
      return 1;
    }
    if (bValue < aValue) {
      return -1;
    }
    // If equal counts, compare topic name.
    return a.compareTo(b);
  });
}

Uri _nextSearchPageURLFromHeaders(Map<String, String> responseHeaders) {
  final String linkHeader = responseHeaders['link'];
  if (linkHeader == null) {
    return null;
  }
  final List<String> links = linkHeader.split(',');
  final int index = links.indexWhere((String link) => link.contains('rel="next"'));
  if (index == -1) {
    return null;
  }
  final String link = links[index];
  final int start = link.indexOf('<') + 1;
  final int end = link.indexOf('>');
  final String nextPageUrlString = link.substring(start, end);
  return Uri.parse(nextPageUrlString);
}

void _processPullRequest(Map<String, dynamic> pullRequest, RepositoryStatus repositoryStatus, Map<String, int> pullRequestCountByTopicAggregator) {
  repositoryStatus.pullRequestCount += 1;
  final DateTime createdAt = DateTime.tryParse(pullRequest['created_at']);
  if (createdAt != null) {
    repositoryStatus.totalAgeOfAllPullRequests += DateTime.now().difference(createdAt).inDays;
  }

  final DateTime updatedAt = DateTime.tryParse(pullRequest['updated_at']);
  if (updatedAt != null && DateTime.now().difference(updatedAt).inDays >= RepositoryStatus.stalePullRequestThresholdInDays) {
    repositoryStatus.stalePullRequestCount += 1;
  }
  final String title = pullRequest['title'];
  if (title.startsWith('[')) {
    final int end = title.indexOf(']');
    if (end != -1) {
      final String titleTopic = title.substring(1, end);
      if (titleTopic.isNotEmpty) {
        pullRequestCountByTopicAggregator.putIfAbsent(titleTopic, () => 0);
        pullRequestCountByTopicAggregator[titleTopic] += 1;
      }
    }
  }
}

void _processLabels(Map<String, dynamic> issue, Map<String, int> issueCountByLabelAggregator) {
  final List<dynamic> labelNames = issue['labels'].map((dynamic issue) => issue['name']).toList();

  for (String labelName in labelNames) {
    issueCountByLabelAggregator.putIfAbsent(labelName, () => 0);
    issueCountByLabelAggregator[labelName] += 1;
  }
}

Future<HttpRequest> _getResponse(Uri url) async {
  final Map<String, String> headers = <String, String>{};

  if (GithubAuthentication.isSignedIntoGithub) {
    headers['Authorization'] = 'token ${GithubAuthentication.token}';
  }

  final String requestETag = _eTagByURL[url];
  if (requestETag != null) {
    headers['If-None-Match'] = requestETag;
  }

  final HttpRequest response = await HttpRequest.request(url.toString(), requestHeaders: headers).catchError((Error error) {
    print('Error fetching"$url": $error');
  });

  if (response?.status == HttpStatus.notModified) {
    debugPrint('Github reports query results have not been updated since last check of "$url", skipping.');
  }

  final String responseETag = response?.responseHeaders['etag'];
  if (responseETag != null) {
    _eTagByURL[url] = responseETag;
  }
  return response;
}

Future<dynamic> _getBody(String path, {Map<String, String> queryParameters}) async {
  final Uri url = Uri.https('api.github.com', path, queryParameters);
  final HttpRequest response = await _getResponse(url);
  final String body = response?.response;
  return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
}
