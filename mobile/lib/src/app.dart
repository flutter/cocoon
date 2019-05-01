// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'agents/agents.dart';
import 'benchmarks/benchmarks.dart';
import 'build_status/build_status.dart';
import 'tasks/tasks.dart';

class MetapodApp extends StatefulWidget {
  const MetapodApp();

  @override
  _MetapodAppState createState() => _MetapodAppState();
}

class _MetapodAppState extends State<MetapodApp> {
  var _currentIndex = 0;

  Widget _body() {
    switch (_currentIndex) {
      case 0:
        return const BuildPage();
      case 1:
        return const BenchmarksPage();
      case 2:
        return const AgentsPage();
      case 3:
        return const TasksPage();
    }
    return null;
  }

  void _handleTap(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
      bottomNavigationBar: MetapodBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleTap,
      ),
    );
  }
}

class MetapodBottomNavigationBar extends StatelessWidget {
  const MetapodBottomNavigationBar({
    @required this.currentIndex,
    @required this.onTap,
  });

  final int currentIndex;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.build),
          title: const Text('Build'),
          backgroundColor: theme.primaryColor,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.timer),
          title: const Text('Benchmarks'),
          backgroundColor: theme.primaryColor,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_outline),
          activeIcon: const Icon(Icons.people),
          title: const Text('Agents'),
          backgroundColor: theme.primaryColor,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt),
          title: const Text('Tasks'),
          backgroundColor: theme.primaryColor,
        ),
      ],
      onTap: onTap,
    );
  }
}
