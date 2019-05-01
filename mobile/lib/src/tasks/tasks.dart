// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../entities.dart';
import '../providers.dart';
import '../utils/framework.dart';
import '../utils/semantics.dart';

import 'details.dart';

class TasksPage extends StatelessWidget {
  const TasksPage();

  @override
  Widget build(BuildContext context) {
    var buildStatusModel = BuildStatusProvider.of(context);
    return RequestOnce(
      callback: () {
        buildStatusModel.requestBuildStatus();
      },
      child: TasksPageBody(
        loaded: buildStatusModel.isLoaded,
        statuses: buildStatusModel.statuses ?? const [],
      ),
    );
  }
}

class TasksPageBody extends StatelessWidget {
  const TasksPageBody({
    @required this.loaded,
    @required this.statuses,
  });

  final bool loaded;
  final List<BuildStatus> statuses;

  @override
  Widget build(BuildContext context) {
    var slivers = <Widget>[
      SliverAppBar(
        title: const Text('Tasks'),
        floating: true,
      )
    ];
    if (loaded) {
      var stages = statuses.first.stages;
      var tasks = <Task>[];
      for (var stage in stages) {
        tasks.addAll(stage.tasks.map((entity) => entity.task));
      }
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) {
              return const Divider(height: 1);
            } else {
              return TaskInfoTile(task: tasks[index ~/ 2]);
            }
          },
          childCount: tasks.length * 2,
          semanticIndexCallback: evenSemanticIndexes,
        ),
      ));
    } else {
      slivers.add(
        const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading'),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).primaryColorDark),
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).canvasColor),
          child: CustomScrollView(
            slivers: slivers,
            semanticChildCount: loaded ? statuses.first.stages.length : 1,
          ),
        ),
      ),
    );
  }
}

class TaskInfoTile extends StatelessWidget {
  const TaskInfoTile({@required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: StageAvatar(stageName: task.stageName),
      title: Text(task.name, overflow: TextOverflow.ellipsis),
      trailing: task.isFlaky ? const Text('Flaky', style: TextStyle(fontStyle: FontStyle.italic)) : null,
      onTap: () {
        Navigator.of(context).push<void>(MaterialPageRoute(builder: (context) {
          return TaskHistoryPage(task: task);
        }));
      },
    );
  }
}

class StageAvatar extends StatelessWidget {
  const StageAvatar({@required this.stageName});

  final String stageName;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (stageName) {
      case 'devicelab':
        child = const Icon(Icons.android);
        break;
      case 'devicelab_win':
        child = const SizedBox(
          child: Center(child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          width: 24,
          height: 24,
        );
        break;
      case 'devicelab_ios':
        child = const SizedBox(
          child: Center(child: Text('A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          width: 24,
          height: 24,
        );
        break;
      case 'cirrus':
        child = const SizedBox(
          child: Center(child: Text('C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          width: 24,
          height: 24,
        );
        break;
      case 'chromebot':
        child = const Icon(Icons.camera);
        break;
      default:
        child = const Center(child: Text('?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)));
    }
    return Semantics(
      label: stageName,
      excludeSemantics: true,
      child: CircleAvatar(child: child),
    );
  }
}
