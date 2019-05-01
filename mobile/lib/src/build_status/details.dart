// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../entities.dart';
import '../providers.dart';
import '../tasks/details.dart';
import '../tasks/tasks.dart';
import '../utils/framework.dart';

class BuildDetailsPage extends StatelessWidget {
  const BuildDetailsPage({@required this.data});

  final BuildStatus data;

  @override
  Widget build(BuildContext context) {
    final CommitModel commitModel = CommitProvider.of(context);
    var sha = data.checklist.checklist.commit.sha;
    var commit = commitModel.getCommit(sha);
    return RequestOnce(
      callback: () {
        if (commit == null) {
          commitModel.requestCommit(sha);
        }
      },
      child: BuildDetailsBody(
        commit: commit,
        data: data,
      ),
    );
  }
}

class BuildDetailsBody extends StatelessWidget {
  const BuildDetailsBody({
    @required this.data,
    @required this.commit,
  });

  final BuildStatus data;
  final Map<String, Object> commit;

  @override
  Widget build(BuildContext context) {
    var clockModel = ClockProvider.of(context);
    String time;
    var currentTime = clockModel.currentTime();
    var commitTime = data.checklist.checklist.createTimestamp;
    if (commitTime.difference(currentTime).inDays > 1) {
      time = '${commitTime.month} ${commitTime.day}';
    } else {
      var hour = commitTime.hour;
      var minute = commitTime.minute;
      var isPm = hour >= 12;
      if (hour > 12) {
        hour -= 12;
      }
      time = '$hour:${minute == 0 ? '00' : minute} ${isPm ? 'PM' : 'AM'}';
    }
    var failed = <TaskEntity>[];
    var failedFlaky = <TaskEntity>[];
    var pending = <TaskEntity>[];
    var underperformed = <TaskEntity>[];
    var unknown = <TaskEntity>[];
    for (var stage in data.stages) {
      for (var task in stage.tasks) {
        if (task.task.status == 'Succeeded') {
        } else if (task.task.status == 'Failed') {
          if (task.task.isFlaky) {
            failedFlaky.add(task);
          } else {
            failed.add(task);
          }
        } else if (task.task.status == 'In Progress') {
          pending.add(task);
        } else if (task.task.status == 'Underperformed') {
          underperformed.add(task);
        } else {
          unknown.add(task);
        }
      }
    }
    var children = <Widget>[];
    if (pending.isNotEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Pending', style: TextStyle(fontSize: 24)),
      ));
      for (var task in pending) {
        children.add(TaskTile(task: task));
      }
      children.add(const Divider());
    }
    if (failed.isNotEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Failed', style: TextStyle(fontSize: 24)),
      ));
      for (var task in failed) {
        children.add(TaskTile(task: task));
      }
    }
    if (failedFlaky.isNotEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Flaked', style: TextStyle(fontSize: 24)),
      ));
      for (var task in failedFlaky) {
        children.add(TaskTile(task: task));
      }
    }
    if (underperformed.isNotEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Underperformed', style: TextStyle(fontSize: 24)),
      ));
      for (var task in underperformed) {
        children.add(TaskTile(task: task));
      }
    }
    return Scaffold(
      body: CustomScrollView(slivers: [
        const SliverAppBar(
          title: Text('Build Report'),
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: ListTile(
            leading: Hero(
              tag: data,
              child: CircleAvatar(
                backgroundImage: NetworkImage(data.checklist.checklist.commit.author.avatarUrl),
              ),
            ),
            title: Text('flutter/${data.checklist.checklist.commit.sha.substring(0, 6)}'),
            subtitle: Text(time),
            onTap: () {
              launch('https://github.com/flutter/flutter/commit/${data.checklist.checklist.commit.sha}');
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: commit == null ? const SizedBox() : Text((commit['commit'] as Map<String, Object>)['message']),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate(children),
        ),
        SliverToBoxAdapter(
          child: Container(height: 50),
        )
      ]),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    var signInModel = SignInProvider.of(context);
    return ListTile(
      dense: true,
      leading: StageAvatar(stageName: task.task.stageName),
      title: Text(task.task.name),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(task.task.name),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('History'),
                  onTap: () {
                    var navigator = Navigator.of(context);
                    navigator.pushReplacement<void, void>(MaterialPageRoute(builder: (context) {
                      return TaskHistoryPage(task: task.task);
                    }));
                  },
                ),
                // ListTile(
                //   leading: const Icon(Icons.redo),
                //   title: const Text('Restart'),
                //   enabled: signInModel.googleAccount != null,
                //   onTap: () => BuildStatusProvider.of(context).resetTask(task.key),
                // ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Logs'),
                  enabled: signInModel.isSignedIntoCocoon,
                  onTap: null,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
