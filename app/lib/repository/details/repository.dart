// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;

import 'package:intl/intl.dart';
import 'package:flutter_web/material.dart';

import '../models/providers.dart';
import '../models/repository_status.dart';

typedef LabelEvaluator = bool Function(String labelName);

class RepositoryDetails<T extends RepositoryStatus> extends StatelessWidget {
  const RepositoryDetails({@required this.icon, this.labelEvaluation});

  final Widget icon;
  final LabelEvaluator labelEvaluation;

  @override
  Widget build(BuildContext context) {
    final T repositoryStatus = ModelBinding.of<T>(context);
    final FlutterRepositoryStatus flutterStatus = ModelBinding.of<FlutterRepositoryStatus>(context);
    final NumberFormat numberFormat = NumberFormat('#,###');
    final Widget refreshWidget = RefreshRepository<T>(
      child: Column(
        children: <Widget>[
          _PullRequestWidget<T>(),
          _IssueWidget<T>(),
          // The Flutter repository contains labels relevant to some other repos like plugins, engine, etc.
          _TopicListWidget(title: 'Relevant Issue and PR Labels', countByTopic: flutterStatus.issueCountByLabelName, labelEvaluation: labelEvaluation),
          _TopicListWidget(title: 'Pull Requests by Topic', countByTopic: repositoryStatus.pullRequestCountByTitleTopic)
        ]
      )
    );
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
            refreshWidget
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
      final int issueCount = repositoryStatus.issueCount;

      final int ageDays = (repositoryStatus.totalAgeOfAllIssues / issueCount).round();
      final String age = Intl.plural(ageDays, zero: '0 days', one: '1 day', other: '$ageDays days');
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
        children: issueWidgets ?? const <Widget>[]
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
      final int pullRequestCount = repositoryStatus.pullRequestCount;

      final int ageDays = (repositoryStatus.totalAgeOfAllPullRequests / pullRequestCount).round();
      final String age = Intl.plural(ageDays, zero: '0 days', one: '1 day', other: '$ageDays days');

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
        children: pullRequestsWidgets ?? const <Widget>[]
      )
    );
  }
}

class _TopicListWidget extends StatelessWidget {
  const _TopicListWidget({@required this.title, @required this.countByTopic, this.labelEvaluation});

  final String title;
  final LabelEvaluator labelEvaluation;
  final SplayTreeMap<String, int> countByTopic;

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');

    // The Flutter repository contains labels relevant to plugins, engine, etc.
    final List<Widget> labelWidgets = <Widget>[];

    countByTopic.forEach((String labelName, int count) {
      if ((labelEvaluation == null || labelEvaluation(labelName)) && labelWidgets.length < 5) {
        labelWidgets.add(_DetailItem(title: labelName, value: numberFormat.format(count)));
      }
    });
    if (labelWidgets.isNotEmpty) {
      labelWidgets.insert(0, const Divider());
      labelWidgets.insert(1, _DetailTitle(title: title));
    } else {
      return const SizedBox();
    }
    return Semantics(
      label: title,
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
          Text('$title: ', style: textTheme.subtitle.copyWith(fontSize: textTheme.subhead.fontSize)),
          Text(value, style: textTheme.subhead),
        ],
      )
    );
  }
}
