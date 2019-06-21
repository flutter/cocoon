// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;

import 'package:intl/intl.dart';
import 'package:flutter_web/material.dart';

import '../models/providers.dart';
import '../models/repository_status.dart';

class RepositoryDetails<T extends RepositoryStatus> extends StatelessWidget {
  const RepositoryDetails({@required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final T repositoryStatus = ModelBinding.of<T>(context);
    final FlutterRepositoryStatus flutterStatus = ModelBinding.of<FlutterRepositoryStatus>(context);
    return RefreshRepository<T>(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _RepositoryInfoWidget<T>(icon: icon),
          // The Flutter repository contains labels relevant to some other repos like plugins, engine, etc. Avoiding displaying twice in the Flutter repository widget.
          if (repositoryStatus.runtimeType != flutterStatus.runtimeType)
            _TopicListWidget(title: 'Flutter Pull Request Labels', countByTopic: flutterStatus.pullRequestCountByLabelName, labelEvaluation: repositoryStatus.labelEvaluation),
          _TopicListWidget(title: 'Pull Request Labels', countByTopic: repositoryStatus.pullRequestCountByLabelName, labelEvaluation: repositoryStatus.labelEvaluation),
          _TopicListWidget(title: 'Pull Requests by Topic', countByTopic: repositoryStatus.pullRequestCountByTitleTopic)
        ]
      ),
    );
  }
}

class _RepositoryInfoWidget<T extends RepositoryStatus> extends StatelessWidget {
  const _RepositoryInfoWidget({@required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final T repositoryStatus = ModelBinding.of<T>(context);
    return Expanded(
      child: Padding(padding: const EdgeInsets.only(right: 50.0),
        child: Column(
          children: <Widget>[
            _MetadataWidget<T>(icon: icon),
            if (repositoryStatus.pullRequestCount > 0)
              _PullRequestWidget<T>(),
            if (repositoryStatus.issueCount > 0)
              _IssueWidget<T>(),
          ]
        )
      )
    );
  }
}

class _MetadataWidget<T extends RepositoryStatus> extends StatelessWidget {
  const _MetadataWidget({@required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');
    final T repositoryStatus = ModelBinding.of<T>(context);

    List<Widget> issueWidgets = <Widget>[
      ListTile(
        leading: IconTheme(data: IconTheme.of(context).copyWith(size: 60.0, color: Theme.of(context).primaryColorLight), child: icon),
        title: Text(toBeginningOfSentenceCase(repositoryStatus.name)),
      ),
      _DetailItem(title: 'Watchers', value: numberFormat.format(repositoryStatus.watchersCount)),
      _DetailItem(title: 'Subscribers', value: numberFormat.format(repositoryStatus.subscribersCount)),
      _DetailItem(title: 'TODOs', value: numberFormat.format(repositoryStatus.todoCount)),
    ];
    return Column(
      children: issueWidgets
    );
  }
}


class _IssueWidget<T extends RepositoryStatus> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');
    final NumberFormat percentFormat = NumberFormat.percentPattern();
    final T repositoryStatus = ModelBinding.of<T>(context);

    final int issueCount = repositoryStatus.issueCount;
    return Column(
      children: <Widget>[
        const Divider(height: 40.0),
        const _DetailTitle(title: 'Issues'),
        _DetailItem(title: 'Open', value: numberFormat.format(issueCount)),
        _DetailItem(title: 'No Labels', value: '${numberFormat.format(repositoryStatus.missingLabelsIssuesCount)} (${percentFormat.format(repositoryStatus.missingLabelsIssuesCount / issueCount)})'),
        _DetailItem(title: 'Unmodified in month', value: '${numberFormat.format(repositoryStatus.staleIssueCount)} (${percentFormat.format(repositoryStatus.staleIssueCount / issueCount)})'),
      ]
    );
  }
}

class _PullRequestWidget<T extends RepositoryStatus> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('#,###');
    final NumberFormat percentFormat = NumberFormat.percentPattern();
    final T repositoryStatus = ModelBinding.of<T>(context);

    final int pullRequestCount = repositoryStatus.pullRequestCount;

    final int ageDays = (repositoryStatus.totalAgeOfAllPullRequests / pullRequestCount).round();
    final String age = Intl.plural(ageDays, zero: '0 days', one: '1 day', other: '$ageDays days');

    return Semantics(
      label: 'Pull Requests',
      child: Column(
        children: <Widget>[
          const Divider(height: 40.0),
          const _DetailTitle(title: 'Pull Requests'),
          _DetailItem(title: 'Open', value: numberFormat.format(pullRequestCount)),
          _DetailItem(title: 'Average Age', value: age),
          _DetailItem(title: 'Unmodified in week', value: '${numberFormat.format(repositoryStatus.stalePullRequestCount)} (${percentFormat.format(repositoryStatus.stalePullRequestCount / pullRequestCount)})'),
        ]
      ),
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
      if ((labelEvaluation == null || labelEvaluation(labelName)) && labelWidgets.length < 17) {
        labelWidgets.add(_DetailItem(title: labelName, value: numberFormat.format(count)));
      }
    });
    if (labelWidgets.isNotEmpty) {
      labelWidgets.insert(0, _DetailTitle(title: title));
    } else {
      return const SizedBox();
    }
    return Expanded(
      child: Semantics(
        label: title,
        child: Column(
          children: labelWidgets
        ),
      ),
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle({@required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headline.copyWith(
          color: Theme.of(context).primaryColor,
        )
      )
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
