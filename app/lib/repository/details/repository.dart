// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;

import 'package:intl/intl.dart';
import 'package:flutter_web/material.dart';

import '../models/repository_status.dart';
import '../models/providers.dart';

typedef LabelEvaluator = bool Function(String labelName);

class RepositoryDetails<T extends RepositoryStatus> extends StatelessWidget {
  const RepositoryDetails({@required this.icon, this.labelEvaluation});

  final Widget icon;
  final LabelEvaluator labelEvaluation;

  @override
  Widget build(BuildContext context) {
    final T repositoryStatus = ModelBinding.of<T>(context);
    final NumberFormat numberFormat = NumberFormat('#,###');
    return Card(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
              children: <Widget>[
                ListTile(
                  leading: IconTheme(data: Theme.of(context).iconTheme.copyWith(size: 36.0), child: icon),
                  title: Text(toBeginningOfSentenceCase(repositoryStatus.name)),
                  subtitle: Text('Watchers: ${numberFormat.format(repositoryStatus.watchersCount)}\nSubscribers: ${numberFormat.format(repositoryStatus.subscribersCount)}\nTODOs: ${numberFormat.format(repositoryStatus.todoCount)}'),
                  trailing: Image.network('https://api.cirrus-ci.com/github/flutter/${repositoryStatus.name}.svg?branch=master', semanticLabel: 'Cirrus CI status'), // TODO: Refresh CI image periodically.
                  isThreeLine: true,
                ),
                RefreshRepository<T>(
                    child: Column(
                        children: <Widget>[
                          _PullRequestWidget<T>(),
                          _IssueWidget<T>(),
                          if (labelEvaluation != null)
                            _LabelWidget(labelEvaluation: labelEvaluation),
                          _PullRequestTopicWidget<T>()
                        ]
                    )
                )
              ]
          )
      ),
    );
  }
}

class _IssueWidget<T extends RepositoryStatus> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');
    final NumberFormat percentFormat = NumberFormat.percentPattern();
    final T repositoryStatus = ModelBinding.of<T>(context);

    List<Widget> issueWidgets;
    if (repositoryStatus.issueCount > 0) {
      int issueCount = repositoryStatus.issueCount;

      int ageDays = (repositoryStatus.totalAgeOfAllIssues / issueCount).round();
      String age = Intl.plural(ageDays, zero: '0 days', one: '1 day', other: '$ageDays days');
      issueWidgets = <Widget>[
        const Divider(),
        const _DetailTitle(title: 'Issues'),
        _DetailItem(title: 'Open', value: numberFormat.format(issueCount)),
        _DetailItem(title: 'No Milestone', value: '${numberFormat.format(repositoryStatus.missingMilestoneIssuesCount)} (${percentFormat.format(repositoryStatus.missingMilestoneIssuesCount / issueCount)})'),
        _DetailItem(title: 'Average Age', value: age),
        _DetailItem(title: 'Unmodified in month', value: '${numberFormat.format(repositoryStatus.staleIssueCount)} (${percentFormat.format(repositoryStatus.staleIssueCount / issueCount)})'),
      ];
    }
    return Semantics(
        label: 'Issues',
        child: Column(
            children: issueWidgets ?? []
        )
    );
  }
}

class _PullRequestWidget<T extends RepositoryStatus> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');
    final NumberFormat percentFormat = NumberFormat.percentPattern();
    final T repositoryStatus = ModelBinding.of<T>(context);

    List<Widget> pullRequestsWidgets;
    if (repositoryStatus.pullRequestCount > 0) {
      int pullRequestCount = repositoryStatus.pullRequestCount;

      int ageDays = (repositoryStatus.totalAgeOfAllPullRequests / pullRequestCount).round();
      String age = Intl.plural(ageDays, zero: '0 days', one: '1 day', other: '$ageDays days');

      pullRequestsWidgets = <Widget>[
        const _DetailTitle(title: 'Pull Requests'),
        _DetailItem(title: 'Open', value: numberFormat.format(pullRequestCount)),
        _DetailItem(title: 'Average Age', value: age),
        _DetailItem(title: 'Unmodified in week', value: '${numberFormat.format(repositoryStatus.stalePullRequestCount)} (${percentFormat.format(repositoryStatus.stalePullRequestCount / pullRequestCount)})'),
      ];
    }
    return Semantics(
        label: 'Pull Requests',
        child: Column(
            children: pullRequestsWidgets ?? []
        )
    );
  }
}

class _PullRequestTopicWidget<T extends RepositoryStatus> extends StatelessWidget {
  const _PullRequestTopicWidget();

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');

    final T repositoryStatus = ModelBinding.of<T>(context);
    Map<String, int> pullRequestCountByTitleTopic = repositoryStatus.pullRequestCountByTitleTopic;
    if (pullRequestCountByTitleTopic.isEmpty) {
      return Container();
    }

    List<Widget> topicWidgets = [];
    SplayTreeMap<String, int> sortedFetchedPRCountByTopic = SplayTreeMap.from(pullRequestCountByTitleTopic, (a, b) {
      // Sort PRs map by number, descending. If equal, compare topic name.
      int aValue = pullRequestCountByTitleTopic[a];
      int bValue = pullRequestCountByTitleTopic[b];
      if (bValue > aValue) return 1;
      if (bValue < aValue) return -1;
      return a.compareTo(b);
    });
    sortedFetchedPRCountByTopic.forEach((topic, count) {
      if (topicWidgets.length < 5) {
        topicWidgets.add(_DetailItem(title: topic, value: numberFormat.format(count)));
      }
    });
    if (topicWidgets.isNotEmpty) {
      topicWidgets.insert(0, const Divider());
      topicWidgets.insert(1, const _DetailTitle(title: 'Pull Requests by Topic'));
    }
    return Semantics(
        label: 'Pull Requests by Topic',
        child: Column(
            children: topicWidgets
        )
    );
  }
}

class _LabelWidget extends StatelessWidget {
  const _LabelWidget({@required this.labelEvaluation});

  final LabelEvaluator labelEvaluation;

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');

    // The Flutter repository contains labels relevant to plugins, engine, etc.
    final FlutterRepositoryStatus flutterStatus = ModelBinding.of<FlutterRepositoryStatus>(context);
    List<Widget> labelWidgets = [];
    Map<String, int> fetchedIssueCountByLabelName = flutterStatus.issueCountByLabelName;
    if (fetchedIssueCountByLabelName.isNotEmpty) {
      SplayTreeMap<String, int> sortedFetchedIssueCountByLabel = SplayTreeMap.from(fetchedIssueCountByLabelName, (a, b) {
        // Sort issues map by number of issues, descending. If equal, compare label name.
        int aValue = fetchedIssueCountByLabelName[a];
        int bValue = fetchedIssueCountByLabelName[b];
        if (bValue > aValue) return 1;
        if (bValue < aValue) return -1;
        return a.compareTo(b);
      });
      sortedFetchedIssueCountByLabel.forEach((labelName, count) {
        if (labelEvaluation(labelName) && labelWidgets.length < 5) {
          labelWidgets.add(_DetailItem(title: labelName, value: numberFormat.format(count)));
        }
      });
      if (labelWidgets.isNotEmpty) {
        labelWidgets.insert(0, const Divider());
        labelWidgets.insert(1, const _DetailTitle(title: 'Labels on Flutter Issues and PRs'));
      }
    }
    return Semantics(
        label: 'Relevant Issue and PR Labels',
        child: Column(
            children: labelWidgets
        )
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle({@required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
        header: true,
        label: title,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Text(title, style: textTheme.subhead),
        )
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({@required this.title, @required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text('${title}: ', style: textTheme.subtitle.copyWith(fontSize: textTheme.subhead.fontSize)),
            Text(value, style: textTheme.subhead),
          ],
        )
    );
  }
}
