// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web/material.dart';

import '../models/build_status.dart';
import '../models/github_status.dart';
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
          labelStyle: ChipTheme.of(context).labelStyle.apply(fontSizeFactor: 1.8)
        ),
      ),
      child: ModelBinding<BuildStatus>(
        initialModel: const BuildStatus(),
        child: RefreshBuildStatus(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    const _BuildStatusWidget(),
                    ModelBinding<GithubStatus>(
                      initialModel: const GithubStatus(),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.code),
                          radius: _kAvatarRadius,
                        ),
                        title: const Text('Github'),
                        subtitle: const _GithubStatusIndicator(),
                      ),
                    ),
                  ]
                ),
              ),
              const _FailingAgentWidget()
            ]
          ),
        ),
      ),
    );
  }
}

class _GithubStatusIndicator extends StatelessWidget {
  const _GithubStatusIndicator();

  @override
  Widget build(BuildContext context) {
    final GithubStatus githubStatus = ModelBinding.of<GithubStatus>(context);
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
        icon = Icons.error;
        backgroundColor = Colors.redAccent;
        break;
      default:
        icon = Icons.help_outline;
        backgroundColor = Colors.grey;
    }
    return Semantics(
      child: RefreshGithubStatus(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Chip(
            avatar: Icon(icon),
            backgroundColor: backgroundColor,
            label: Text(githubStatus.status ?? 'Unknown')
          ),
        ),
      ),
      hint: 'Github Status',
    );
  }
}

class _BuildStatusWidget extends StatelessWidget {
  const _BuildStatusWidget();

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
        icon = Icons.error;
        backgroundColor = Colors.redAccent;
        break;
      default:
        icon = Icons.help_outline;
        backgroundColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
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
            label: Text(status.anticipatedBuildStatus ?? 'Unknown')
          ),
        ),
        hint: 'Build Status',
      ),
    );
  }
}

class _FailingAgentWidget extends StatelessWidget {
  const _FailingAgentWidget();

  @override
  Widget build(BuildContext context) {
    final BuildStatus status = ModelBinding.of<BuildStatus>(context);
    final List<String> failingAgents = status.failingAgents;
    if (failingAgents.isEmpty) {
      return const SizedBox();
    }

    return Expanded(
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text('Failing Agents',
              style: Theme.of(context).textTheme.headline.copyWith(
                color: Theme.of(context).primaryColor,
              )),
          ),
          for (String agentName in failingAgents)
            ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.desktop_windows),
                radius: _kAvatarRadius,
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              title: Text('$agentName Unhealthy')
            )
        ]
      )
    );
  }
}
