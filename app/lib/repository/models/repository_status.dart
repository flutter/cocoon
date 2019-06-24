// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection' show SplayTreeMap;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';
import 'package:flutter_web/widgets.dart';

import '../services/github_service.dart';
import 'providers.dart';

typedef LabelEvaluator = bool Function(String labelName);

/// Repository properties and status fetched from Github.
///
/// [name] is the Github ":repo" parameter in Github APIs. See <https://developer.github.com/v3/repos>
abstract class RepositoryStatus {
  RepositoryStatus({@required this.name, @required this.labelEvaluation});

  final String name;

  /// Should true if the pull request has a PR triage label, or other label interesting to the maintainers.
  /// See <https://github.com/flutter/flutter/wiki/Triage#critical-issue-triage>
  final LabelEvaluator labelEvaluation;

  static const int staleIssueThresholdInDays = 30;
  static const int stalePullRequestThresholdInDays = 7;

  int watchersCount = 0;
  int subscribersCount = 0;
  bool issuesEnabled = false;
  int todoCount = 0;

  int issueCount = 0;
  int missingLabelsIssuesCount = 0;
  /// Number of issues that have been unmodified in [staleIssueThresholdInDays] days.
  int staleIssueCount = 0;

  int pullRequestCount = 0;

  /// Number of pull requests that have been unmodified in [stalePullRequestThresholdInDays] days.
  int stalePullRequestCount = 0;
  /// Total age in days. Used to find average age: [totalAgeOfAllPullRequests] / [pullRequestCount].
  int totalAgeOfAllPullRequests = 0;

  /// Primary sort is count descending, secondary sort is label ascending alphabetically.
  ///
  /// Sorted example where engine, framework, and tool are sorted alphabetically with the same count, followed by bug with a smaller count:
  /// - engine: 10
  /// - framework: 10
  /// - tool: 10
  /// - bug: 9
  SplayTreeMap<String, int> pullRequestCountByLabelName = SplayTreeMap<String, int>();

  /// Pull requests titles are sometimes prefixed by topics between square brackets.
  /// Primary sort is count descending, secondary sort is topic ascending alphabetically.
  ///
  /// See [pullRequestCountByLabelName] sorted example.
  SplayTreeMap<String, int> pullRequestCountByTitleTopic = SplayTreeMap<String, int>();

  RepositoryStatus copy() {
    return statusFactory()
      ..watchersCount = watchersCount
      ..subscribersCount = subscribersCount
      ..issuesEnabled = issuesEnabled
      ..todoCount = todoCount
      ..issueCount = issueCount
      ..pullRequestCount = pullRequestCount
      ..missingLabelsIssuesCount = missingLabelsIssuesCount
      ..staleIssueCount = staleIssueCount
      ..stalePullRequestCount = stalePullRequestCount
      ..totalAgeOfAllPullRequests = totalAgeOfAllPullRequests
      ..pullRequestCountByLabelName = pullRequestCountByLabelName
      ..pullRequestCountByTitleTopic = pullRequestCountByTitleTopic;
  }

  /// This abstract class is used as a generic in some places. This factory method allows it to be instantiated as a generic.
  ///
  /// See <https://github.com/dart-lang/sdk/issues/10667>
  RepositoryStatus statusFactory();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final RepositoryStatus typedOther = other;
    return (typedOther.name == name)
      && (typedOther.labelEvaluation == labelEvaluation)
      && (typedOther.watchersCount == watchersCount)
      && (typedOther.subscribersCount == subscribersCount)
      && (typedOther.issuesEnabled == issuesEnabled)
      && (typedOther.todoCount == todoCount)
      && (typedOther.issueCount == issueCount)
      && (typedOther.missingLabelsIssuesCount == missingLabelsIssuesCount)
      && (typedOther.staleIssueCount == staleIssueCount)
      && (typedOther.pullRequestCount == pullRequestCount)
      && (typedOther.stalePullRequestCount == stalePullRequestCount)
      && (typedOther.totalAgeOfAllPullRequests == totalAgeOfAllPullRequests)
      && (typedOther.pullRequestCountByLabelName == pullRequestCountByLabelName)
      && (typedOther.pullRequestCountByTitleTopic == pullRequestCountByTitleTopic);
  }

  @override
  int get hashCode => hashValues(
    name,
    labelEvaluation,
    pullRequestCountByLabelName,
    pullRequestCountByTitleTopic,
    watchersCount,
    subscribersCount,
    issuesEnabled,
    todoCount,
    issueCount,
    missingLabelsIssuesCount,
    staleIssueCount,
    pullRequestCount,
    stalePullRequestCount,
    totalAgeOfAllPullRequests);
}

class FlutterRepositoryStatus extends RepositoryStatus {
  FlutterRepositoryStatus() : super(name: 'flutter', labelEvaluation: (String labelName) => const <String>[
    'waiting for tree to go green',
    '⚠ TODAY',
    'severe: customer blocker',
    'severe: customer critical',
    'f: cupertino',
    'f: material design',
    'tool',
    'will need additional triage',
  ].contains(labelName));

  @override
  FlutterRepositoryStatus statusFactory() {
    return FlutterRepositoryStatus();
  }
}

class FlutterEngineRepositoryStatus extends RepositoryStatus {
  FlutterEngineRepositoryStatus() : super(
    name: 'engine',
    labelEvaluation: (String labelName) => labelName == 'engine'
      || labelName == 'needs love'
      || labelName.startsWith('e:')
      || labelName.startsWith('affects:'));

  @override
  FlutterEngineRepositoryStatus statusFactory() {
    return FlutterEngineRepositoryStatus();
  }
}

class FlutterPluginsRepositoryStatus extends RepositoryStatus {
  FlutterPluginsRepositoryStatus() : super(
    name: 'plugins',
    labelEvaluation: (String labelName) => labelName.startsWith('p:')
      || labelName == 'waiting for test harness'
      || labelName == 'flutterfire'
      || labelName == 'needs love');

  @override
  FlutterPluginsRepositoryStatus statusFactory() {
    return FlutterPluginsRepositoryStatus();
  }
}

class RefreshRepository<T extends RepositoryStatus> extends StatefulWidget {
  const RefreshRepository({@required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshRepositoryState<T>();
  }
}

class _RefreshRepositoryState<T extends RepositoryStatus> extends State<RefreshRepository<T>> with AutomaticKeepAliveClientMixin<RefreshRepository<T>> {
  Timer _refreshTimer;
  bool _isLoaded = false;

  @override
  void initState() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), _refresh);
    super.initState();
    Timer.run(() => _refresh(null));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh(Timer timer) async {
    // Update with the fast, cheap, possibly cached repository details to show UI ASAP.
    await _updateRepositoryDetails();
    final T repositoryStatus = ModelBinding.of<T>(context).copy();

    try {
      final List<Future<void>> futuresToFetch = <Future<void>>[
        _updatePullRequests(repositoryStatus),
        _updateToDoCount(repositoryStatus)];

      // Not every repository has issues enabled. Avoid unnecessary traffic.
      if (repositoryStatus.issuesEnabled) {
        // Github limits searches to 1000 results. Since there may be more issues than that, explicitly query for the counts instead of iterating over all issues.
        futuresToFetch.addAll(<Future<void>>[
          _updateIssueCount(repositoryStatus),
          _updateStaleIssueCount(repositoryStatus),
          _updateIssuesWithoutLabels(repositoryStatus)]);
      }
      await Future.wait(futuresToFetch, eagerError: true);
    } catch (error) {
      print('Error refreshing repository');
    }
    _isLoaded = true;
    ModelBinding.update<T>(context, repositoryStatus);
  }

  Future<void> _updateRepositoryDetails() async {
    if (!mounted) {
      return;
    }
    final T repositoryStatus = ModelBinding.of<T>(context).copy();
    await fetchRepositoryDetails(repositoryStatus);
    ModelBinding.update<T>(context, repositoryStatus);
  }

  Future<void> _updateIssueCount(T repositoryStatus) async {
    if (!mounted) {
      return;
    }
    final int issueCount = await fetchIssueCount(repositoryStatus.name);
    if (issueCount != null) {
      repositoryStatus.issueCount = issueCount;
    }
  }

  Future<void> _updateStaleIssueCount(T repositoryStatus) async {
    if (!mounted) {
      return;
    }
    final int staleIssueCount = await fetchStaleIssueCount(repositoryStatus.name);
    if (staleIssueCount != null) {
      repositoryStatus.staleIssueCount = staleIssueCount;
    }
  }

  Future<void> _updateIssuesWithoutLabels(T repositoryStatus) async {
    if (!mounted) {
      return;
    }
    final int missingLabelsIssuesCount = await fetchIssuesWithoutLabels(repositoryStatus.name);
    if (missingLabelsIssuesCount != null) {
      repositoryStatus.missingLabelsIssuesCount = missingLabelsIssuesCount;
    }
  }

  Future<void> _updatePullRequests(T repositoryStatus) async {
    if (!mounted) {
      return;
    }
    await fetchPullRequests(repositoryStatus);
  }

  Future<void> _updateToDoCount(T repositoryStatus) async {
    if (!mounted) {
      return;
    }

    final int todoCount = await fetchToDoCount(repositoryStatus.name);
    if (todoCount != null) {
      repositoryStatus.todoCount = todoCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isLoaded ? widget.child : const Center(child: CircularProgressIndicator());
  }
}
