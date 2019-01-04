// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../entities.dart';
import '../providers.dart';

class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    var buildStatusModel = BuildStatusProvider.of(context);
    var tasks = <Task>[];
    for (var status in buildStatusModel.statuses) {
      for (var stage in status.stages) {
        for (var taskEntity in stage.tasks) {
          if (taskEntity.task.name == task.name) {
            tasks.add(taskEntity.task);
          }
        }
      }
    }
    var slivers = <Widget>[
      const SliverAppBar(
        title: Text('Task History'),
        pinned: true,
      ),
      SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 32,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          var task = tasks[index];
          switch (task.status) {
            case 'Succeeded':
              return Container(
                width: 32,
                height: 32,
                child: task.isFlaky ? const Center(child: Text('?')) : null,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  border: Border.all(color: Colors.black),
                ),
              );
            case 'Failed':
              return Container(
                width: 32,
                height: 32,
                child: task.isFlaky ? const Center(child: Text('?')) : null,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.black),
                ),
              );
            case 'New':
              return Container(
                width: 32,
                height: 32,
                child: task.isFlaky ? const Center(child: Text('?')) : null,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.black),
                ),
              );
            case 'In Progress':
              return Container(
                width: 32,
                height: 32,
                child: task.isFlaky ? const Center(child: Text('?')) : null,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  border: Border.all(color: Colors.black),
                ),
              );
            case 'Underperformed':
              return Container(
                width: 32,
                height: 32,
                child: task.isFlaky ? const Center(child: Text('?')) : null,
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  border: Border.all(color: Colors.black),
                ),
              );
            default:
              return Container(
                width: 32,
                height: 32,
                child: task.isFlaky ? const Center(child: Text('?')) : null,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  border: Border.all(color: Colors.black),
                ),
              );
          }
        }, childCount: tasks.length),
      )
    ];
    return Scaffold(
      body: CustomScrollView(
        slivers: slivers,
      ),
    );
  }
}
