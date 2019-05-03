// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../entities.dart';
import '../providers.dart';
import '../utils/framework.dart';
import '../utils/semantics.dart';

import 'details.dart';

class BuildPage extends StatelessWidget {
  const BuildPage();

  @override
  Widget build(BuildContext context) {
    var buildStatusModel = BuildStatusProvider.of(context);
    var buildBrokenModel = BuildBrokenProvider.of(context);
    return RequestOnce(
      callback: () {
        buildStatusModel.requestBuildStatus();
        buildBrokenModel.requestStatus();
      },
      child: BuildPageBody(
        requestBuildStatus: buildStatusModel.requestBuildStatus,
        requestStatus: buildBrokenModel.requestStatus,
        loaded: buildStatusModel.isLoaded,
        lastCommit: buildStatusModel.lastCommit,
        statuses: buildStatusModel.statuses ?? const [],
        broken: buildBrokenModel.isBuildBroken,
      ),
    );
  }
}

class BuildPageBody extends StatelessWidget {
  const BuildPageBody({
    @required this.requestBuildStatus,
    @required this.requestStatus,
    @required this.loaded,
    @required this.lastCommit,
    @required this.statuses,
    @required this.broken,
  });

  final Future<void> Function({bool force}) requestBuildStatus;
  final Future<void> Function() requestStatus;
  final bool loaded;
  final bool broken;
  final CommitInfo lastCommit;
  final List<BuildStatus> statuses;

  @override
  Widget build(BuildContext context) {
    var slivers = <Widget>[
      SliverAppBar(
        title: const Text('Build History'),
        elevation: 0,
        floating: true,
      ),
      SliverPersistentHeader(
        delegate: BuildHeaderDelegate(
          broken: broken,
          loaded: loaded,
          sha: lastCommit?.sha,
        ),
        pinned: true,
      ),
      const SliverToBoxAdapter(
          child: Divider(
        height: 1,
      )),
    ];
    if (!loaded) {
      slivers.add(const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ));
    } else {
      var childCount = statuses.length * 2;
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                return const Divider(height: 1);
              } else {
                return BuildSummary(data: statuses[index ~/ 2]);
              }
            },
            childCount: childCount,
            semanticIndexCallback: evenSemanticIndexes,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).primaryColorDark),
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).canvasColor),
          child: RefreshIndicator(
            onRefresh: () async {
              requestStatus();
              await requestBuildStatus(force: true);
              Scaffold.of(context).showSnackBar(const SnackBar(content: Text('Build updated')));
            },
            child: CustomScrollView(
              semanticChildCount: statuses.length,
              slivers: slivers,
            ),
          ),
        ),
      ),
    );
  }
}

/// The build status shown as a shrinking header.
class BuildHeaderDelegate extends SliverPersistentHeaderDelegate {
  const BuildHeaderDelegate({
    @required this.broken,
    this.loaded = true,
    this.sha,
  });

  /// Whether the build is currently broken.
  final bool broken;

  /// Whether the data required to display this widget is still loading.
  final bool loaded;

  /// The SHA of the last known commit.
  ///
  /// Null if this commit is unknown (loading is true).
  final String sha;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    var theme = Theme.of(context);
    if (!loaded) {
      return const SizedBox(height: 0);
    }
    var shortSha = sha.substring(0, 6);
    var title = broken
        ? Text('flutter/flutter: broken at $shortSha', style: theme.textTheme.title.copyWith(color: Colors.white))
        : Text('flutter/flutter: fixed at $shortSha', style: theme.textTheme.title.copyWith(color: Colors.white));
    var height = math.max(maxExtent - shrinkOffset, minExtent);
    return Material(
      elevation: overlapsContent ? 4 : 0,
      color: broken ? Colors.red : theme.primaryColorDark,
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        alignment: Alignment.centerLeft,
        child: title,
      ),
    );
  }

  @override
  double get maxExtent => 100;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant BuildHeaderDelegate oldDelegate) {
    return oldDelegate.broken != broken || oldDelegate.sha != sha || oldDelegate.loaded != loaded;
  }
}

class BuildSummary extends StatelessWidget {
  const BuildSummary({this.data});

  final BuildStatus data;

  @override
  Widget build(BuildContext context) {
    var clockModel = ClockProvider.of(context);
    var theme = Theme.of(context);
    String time;
    var currentTime = clockModel.currentTime();
    var commitTime = data.checklist.checklist.createTimestamp;
    // hack
    if (currentTime.weekday != commitTime.weekday && currentTime.day != commitTime.day) {
      time = 'on ${commitTime.month}/${commitTime.day}';
    } else {
      var hour = commitTime.hour;
      var minute = commitTime.minute;
      var isPm = hour >= 12;
      if (hour > 12) {
        hour -= 12;
      }
      time = 'at $hour:${minute < 10 ? '0$minute' : minute} ${isPm ? 'PM' : 'AM'}';
    }
    return ListTile(
      onTap: () {
        var navigator = Navigator.of(context);
        navigator.push<void>(MaterialPageRoute(builder: (context) {
          return BuildDetailsPage(data: data);
        }));
      },
      leading: SizedBox(
        width: 36,
        height: 36,
        child: Hero(
          tag: data,
          child: CircleAvatar(
            backgroundColor: theme.canvasColor,
            backgroundImage: NetworkImage(data.checklist.checklist.commit.author.avatarUrl),
          ),
        ),
      ),
      title: Text(
        'flutter/${data.checklist.checklist.commit.sha.substring(0, 6)}',
      ),
      subtitle: Text('Submitted by ${data.checklist.checklist.commit.author.login} $time'),
      isThreeLine: false,
      dense: true,
      trailing: BuildBox(data: data),
    );
  }
}

class BuildBox extends StatelessWidget {
  const BuildBox({this.data});

  final BuildStatus data;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var flakyFailureCount = 0;
    var failedCount = 0;
    var pendingCount = 0;
    for (var stage in data.stages) {
      for (var task in stage.tasks) {
        if (task.task.status == 'Failed') {
          if (task.task.isFlaky) {
            flakyFailureCount += 1;
          }
          failedCount += 1;
        } else if (task.task.status == 'In Progress') {
          pendingCount += 1;
        }
      }
    }
    Widget result;
    if (failedCount == 0 && (pendingCount == 0) ) {
      result = BuildStatusBox(Icons.done, 'Passing', Colors.green);
    } else if (failedCount == 0) {
      result = BuildStatusBox(Icons.watch_later, 'Running', theme.accentColor);
    } else if (flakyFailureCount == failedCount) {
      result = BuildStatusBox(Icons.warning, 'Flaky', Colors.orange);
    } else {
      result = BuildStatusBox(Icons.error_outline, 'Failing', Colors.redAccent);
    }
    if (pendingCount > 0) {
      return Semantics(
        label: 'In Progress',
        child: PendingBox(child: result),
      );
    }
    return result;
  }
}

class BuildStatusBox extends Container {
  BuildStatusBox(
      IconData iconData, String semanticLabel, Color backgroundColor)
      : super(
            width: 36.0,
            height: 36.0,
            child: Center(
              child: Icon(iconData, size: 24.0, color: Colors.white, semanticLabel: semanticLabel),
            ),
            decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: Colors.black54)));
}

class PendingBox extends StatefulWidget {
  const PendingBox({@required this.child});

  final Widget child;

  @override
  _PendingBoxState createState() => _PendingBoxState();
}

class _PendingBoxState extends State<PendingBox> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _opacity;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
    _controller.addListener(() {
      setState(() {});
    });
    _opacity = Tween<double>(begin: 0.8, end: 0.1).animate(_controller);
    _controller.forward();
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
