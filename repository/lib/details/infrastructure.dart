// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/build_status.dart';
import '../models/status_page_status.dart';
import '../models/providers.dart';

const double _kAvatarRadius = 36.0;

class InfrastructureDetails extends StatelessWidget {
  const InfrastructureDetails();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.8),
        chipTheme: ChipTheme.of(context).copyWith(
            labelPadding: const EdgeInsets.fromLTRB(10.0, 3.0, 20.0, 3.0),
            labelStyle: ChipTheme.of(context).labelStyle.apply(fontSizeFactor: 1.8)),
      ),
      child: ModelBinding<BuildStatus>(
        initialModel: const BuildStatus(),
        child: RefreshBuildStatus(
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Expanded(
              child: Column(children: const <Widget>[
                BuildStatusWidget(),
                ModelBinding<StatusPageStatus>(
                    initialModel: StatusPageStatus(),
                    child: RefreshGitHubStatus(
                        child: StatusPageWidget(
                      name: 'GitHub',
                      serviceIcon: Icons.compare_arrows,
                      url: 'https://www.githubstatus.com',
                    ))),
                ModelBinding<StatusPageStatus>(
                    initialModel: StatusPageStatus(),
                    child: RefreshCoverallsStatus(
                        child: StatusPageWidget(
                      name: 'Coveralls',
                      serviceIcon: Icons.code,
                      url: 'https://status.coveralls.io/',
                    )))
              ]),
            ),
            const Expanded(
              child: FailingAgentWidget(),
            ),
            const Expanded(
              child: CommitResultsWidget(),
            )
          ]),
        ),
      ),
    );
  }
}

class StatusPageWidget extends StatelessWidget {
  const StatusPageWidget({@required this.name, @required this.serviceIcon, @required this.url});

  final String name;
  final IconData serviceIcon;
  final String url;

  @override
  Widget build(BuildContext context) {
    final StatusPageStatus githubStatus = ModelBinding.of<StatusPageStatus>(context);
    IconData icon;
    Color backgroundColor;
    switch (githubStatus.indicator) {
      case 'none':
        icon = Icons.check;
        backgroundColor = Colors.green;
        break;
      case 'minor':
        icon = Icons.warning;
        backgroundColor = Colors.amberAccent;
        break;
      case 'major':
        icon = Icons.error;
        backgroundColor = Colors.orangeAccent;
        break;
      case 'critical':
      case 'maintenance':
        icon = Icons.error;
        backgroundColor = Colors.redAccent;
        break;
      default:
        icon = Icons.help_outline;
        backgroundColor = Colors.grey;
    }
    return ListTile(
        leading: CircleAvatar(
          child: Icon(serviceIcon),
          radius: _kAvatarRadius,
        ),
        title: Text(name),
        subtitle: Semantics(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(
                avatar: Icon(icon), backgroundColor: backgroundColor, label: Text(githubStatus.status ?? 'Unknown')),
          ),
        ),
        onTap: () => launch(url));
  }
}

class BuildStatusWidget extends StatelessWidget {
  const BuildStatusWidget();

  @override
  Widget build(BuildContext context) {
    final BuildStatus status = ModelBinding.of<BuildStatus>(context);
    IconData icon;
    Color backgroundColor;
    switch (status.anticipatedBuildStatus) {
      case 'Succeeded':
        icon = Icons.check;
        backgroundColor = Colors.green;
        break;
      case 'Build Will Fail':
      case 'Failed':
        icon = Icons.error;
        backgroundColor = Colors.redAccent;
        break;
      default:
        icon = Icons.help_outline;
        backgroundColor = Colors.grey;
    }

    return ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.devices),
          radius: _kAvatarRadius,
        ),
        title: const Text('Last Flutter Commit'),
        subtitle: Semantics(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(
                avatar: Icon(icon),
                backgroundColor: backgroundColor,
                label: Text(status.anticipatedBuildStatus ?? 'Unknown')),
          ),
          hint: 'Build Status',
        ),
        onTap: () => launch('/build.html'));
  }
}

class FailingAgentWidget extends StatelessWidget {
  const FailingAgentWidget();

  @override
  Widget build(BuildContext context) {
    final BuildStatus status = ModelBinding.of<BuildStatus>(context);
    final List<String> failingAgents = status.failingAgents;
    if (failingAgents.isEmpty) {
      return const SizedBox();
    }

    return Column(children: <Widget>[
      ListTile(
        title: Text('Failing Agents',
            style: Theme.of(context).textTheme.headline.copyWith(
                  color: Theme.of(context).primaryColor,
                )),
      ),
      for (String agentName in failingAgents)
        ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.desktop_windows),
              radius: _kAvatarRadius,
              foregroundColor: Colors.white,
              backgroundColor: Colors.redAccent,
            ),
            title: Text(agentName),
            onTap: () => launch('/build.html'))
    ]);
  }
}

class CommitResultsWidget extends StatelessWidget {
  const CommitResultsWidget();

  @override
  Widget build(BuildContext context) {
    final BuildStatus status = ModelBinding.of<BuildStatus>(context);
    final List<CommitTestResult> commitTestResults = status.commitTestResults;
    if (commitTestResults.isEmpty) {
      return const SizedBox();
    }

    return Column(children: <Widget>[
      for (CommitTestResult commitTestResult in commitTestResults)
        _CommitResultWidget(commitTestResult: commitTestResult)
    ]);
  }
}

class _CommitResultWidget extends StatelessWidget {
  const _CommitResultWidget({this.commitTestResult});

  final CommitTestResult commitTestResult;

  @override
  Widget build(BuildContext context) {
    Widget icon;
    Color backgroundColor;
    if (commitTestResult.failedTestCount > 0) {
      icon = const Icon(Icons.error);
      backgroundColor = Colors.redAccent;
    } else if (commitTestResult.inProgressTestCount > 0) {
      icon = const _PendingIcon(child: const Icon(Icons.sync));
      backgroundColor = Colors.grey[600];
    } else {
      icon = const Icon(Icons.check);
      backgroundColor = Colors.green;
    }

    String displaySha = commitTestResult.sha;
    if (displaySha != null && displaySha.length >= 6) {
      displaySha = displaySha.substring(0, 6);
    }

    return ListTile(
        leading: CircleAvatar(
          child: icon,
          radius: _kAvatarRadius,
          foregroundColor: Colors.white,
          backgroundColor: backgroundColor,
        ),
        title: Text('[$displaySha] ${DateFormat.jm().format(commitTestResult.createDateTime)}'),
        subtitle: RichText(
          text: TextSpan(children: <TextSpan>[
            if (commitTestResult.failedTestCount > 0)
              TextSpan(
                  text:
                      'Fail: ${commitTestResult.failingTests.length == 1 ? commitTestResult.failingTests.first : commitTestResult.failedTestCount}\n',
                  style: const TextStyle(color: Colors.redAccent)),
            if (commitTestResult.failedFlakyTestCount > 0)
              TextSpan(
                  text: 'Flake: ${commitTestResult.failedFlakyTestCount}\n',
                  style: const TextStyle(color: Colors.orange)),
            if (commitTestResult.inProgressTestCount > 0)
              TextSpan(
                  text: 'In progress: ${commitTestResult.inProgressTestCount}',
                  style: const TextStyle(color: Colors.grey)),
          ], style: Theme.of(context).textTheme.subtitle),
        ),
        trailing: CircleAvatar(
          child: Image.network(commitTestResult.avatarImageURL),
          radius: _kAvatarRadius,
        ),
        isThreeLine: true,
        onTap: () => launch('/build.html'));
  }
}

class _PendingIcon extends StatefulWidget {
  const _PendingIcon({@required this.child});

  final Widget child;

  @override
  _PendingIconState createState() => _PendingIconState();
}

class _PendingIconState extends State<_PendingIcon> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _opacity;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    _controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}
