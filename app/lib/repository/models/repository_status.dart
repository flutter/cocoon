// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';
import 'package:flutter_web/widgets.dart';

import '../services/github_service.dart';
import 'providers.dart';

/// Repository properties and status fetched from Github.
///
/// [name] is the Github ":repo" parameter in Github APIs. See <https://developer.github.com/v3/repos>
abstract class RepositoryStatus {
  RepositoryStatus({@required this.name});

  final String name;

  static const int staleIssueThresholdInDays = 30;
  static const int stalePullRequestThresholdInDays = 7;

  int watchersCount = 0;
  int subscribersCount = 0;
  int todoCount = 0;

  int issueCount = 0;
  int missingMilestoneIssuesCount = 0;
  /// Number of issues that have been unmodified in [staleIssueThresholdInDays] days.
  int staleIssueCount = 0;
  /// Total age in days. Used to find average age: [totalAgeOfAllIssues] / [issueCount].
  int totalAgeOfAllIssues = 0;

  int pullRequestCount = 0;

  /// Number of pull requests that have been unmodified in [stalePullRequestThresholdInDays] days.
  int stalePullRequestCount = 0;
  /// Total age in days. Used to find average age: [totalAgeOfAllPullRequests] / [pullRequestCount].
  int totalAgeOfAllPullRequests = 0;
  Map<String, int> issueCountByLabelName = {};

  /// Pull requests titles are sometimes prefixed by topics between square brackets.
  ///
  /// Example: "[firebase_auth] Fix onMethodCall missing for updatePhoneNumberCredential"
  Map<String, int> pullRequestCountByTitleTopic = {};

  RepositoryStatus copy() {
    return statusFactory()
      ..watchersCount = watchersCount
      ..subscribersCount = subscribersCount
      ..todoCount = todoCount
      ..issueCount = issueCount
      ..pullRequestCount = pullRequestCount
      ..missingMilestoneIssuesCount = missingMilestoneIssuesCount
      ..staleIssueCount = staleIssueCount
      ..totalAgeOfAllIssues = totalAgeOfAllIssues
      ..stalePullRequestCount = stalePullRequestCount
      ..totalAgeOfAllPullRequests = totalAgeOfAllPullRequests
      ..issueCountByLabelName = issueCountByLabelName
      ..pullRequestCountByTitleTopic = pullRequestCountByTitleTopic;
  }

  /// This abstract class is used as a generic in some places. This factory method allows it to be instantiated as a generic.
  ///
  /// See <https://github.com/dart-lang/sdk/issues/10667>
  RepositoryStatus statusFactory();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final RepositoryStatus typedOther = other;
    return (typedOther.name == name)
        && (typedOther.watchersCount == watchersCount)
        && (typedOther.subscribersCount == subscribersCount)
        && (typedOther.todoCount == todoCount)
        && (typedOther.issueCount == issueCount)
        && (typedOther.missingMilestoneIssuesCount == missingMilestoneIssuesCount)
        && (typedOther.staleIssueCount == staleIssueCount)
        && (typedOther.totalAgeOfAllIssues == totalAgeOfAllIssues)
        && (typedOther.pullRequestCount == pullRequestCount)
        && (typedOther.stalePullRequestCount == stalePullRequestCount)
        && (typedOther.totalAgeOfAllPullRequests == totalAgeOfAllPullRequests)
        && (typedOther.issueCountByLabelName == issueCountByLabelName)
        && (typedOther.pullRequestCountByTitleTopic == pullRequestCountByTitleTopic);
  }

  @override
  int get hashCode => hashValues(
      name,
      issueCountByLabelName,
      pullRequestCountByTitleTopic,
      watchersCount,
      subscribersCount,
      todoCount,
      issueCount,
      missingMilestoneIssuesCount,
      staleIssueCount,
      totalAgeOfAllIssues,
      pullRequestCount,
      stalePullRequestCount,
      totalAgeOfAllPullRequests);
}

class FlutterRepositoryStatus extends RepositoryStatus {
  FlutterRepositoryStatus() : super(name: 'flutter');

  FlutterRepositoryStatus statusFactory() {
    return FlutterRepositoryStatus();
  }
}

class FlutterEngineRepositoryStatus extends RepositoryStatus {
  FlutterEngineRepositoryStatus() : super(name: 'engine');

  FlutterEngineRepositoryStatus statusFactory() {
    return FlutterEngineRepositoryStatus();
  }
}

class FlutterPluginsRepositoryStatus extends RepositoryStatus {
  FlutterPluginsRepositoryStatus() : super(name: 'plugins');

  FlutterPluginsRepositoryStatus statusFactory() {
    return FlutterPluginsRepositoryStatus();
  }
}

class FlutterPackagesRepositoryStatus extends RepositoryStatus {
  FlutterPackagesRepositoryStatus() : super(name: 'packages');

  FlutterPackagesRepositoryStatus statusFactory() {
    return FlutterPackagesRepositoryStatus();
  }
}

class FlutterWebsiteRepositoryStatus extends RepositoryStatus {
  FlutterWebsiteRepositoryStatus() : super(name: 'website');

  FlutterWebsiteRepositoryStatus statusFactory() {
    return FlutterWebsiteRepositoryStatus();
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

class _RefreshRepositoryState<T extends RepositoryStatus> extends State<RefreshRepository> {
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

  void _refresh(Timer timer) {
    // Update with the fast, cheap, possibly cached repository details to show UI ASAP.
    _fetchRepositoryDetails(() {
      // Then fetch update with the more expensive issues query value.
      _fetchRepositoryIssues(() {
        // Then fetch the less important t_do count.
        _fetchToDoCount(null);
      });
    });
  }

  void _fetchRepositoryDetails(Function nextStep) {
    T refreshedRepositoryStatus = ModelBinding.of<T>(context).copy();

    // Update with the fast, cheap, possibly cached repository details to show UI ASAP.
    GithubService.fetchRepositoryDetails(refreshedRepositoryStatus).then((_) {
      ModelBinding.update<T>(context, refreshedRepositoryStatus);

      // Then fetch update with the more expensive issues query value.
      ModelBinding.of<T>(context).copy();
      if (nextStep != null) nextStep();
    }, onError: (error) {
      print('Error refreshing "${refreshedRepositoryStatus.name}" repository details: $error');
    });
  }

  void _fetchRepositoryIssues(Function nextStep) {
    T refreshedRepositoryStatus = ModelBinding.of<T>(context).copy();
    GithubService.fetchRepositoryIssues(refreshedRepositoryStatus).then((_) {
      ModelBinding.update<T>(context, refreshedRepositoryStatus);

      // Show the UI once critical pieces are fetched.
      _isLoaded = true;
      if (nextStep != null) nextStep();
    }, onError: (error) {
      print('Error refreshing "${refreshedRepositoryStatus.name}" repository issues: $error');
    });
  }

  void _fetchToDoCount(Function nextStep) {
    T refreshedRepositoryStatus = ModelBinding.of<T>(context).copy();
    GithubService.fetchToDoCount(refreshedRepositoryStatus).then((_) {
      ModelBinding.update<T>(context, refreshedRepositoryStatus);
      if (nextStep != null) nextStep();
    }, onError: (error) {
      print('Error refreshing "${refreshedRepositoryStatus.name}" todo count: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded ? widget.child : Center(child: CircularProgressIndicator());
  }
}
