// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:flutter_web/material.dart';

import 'details/infrastructure.dart';
import 'details/repository.dart';
import 'details/roll.dart';
import 'details/settings.dart';
import 'models/providers.dart';
import 'models/repository_status.dart';
import 'models/tab_state.dart' as tab;

const String kTitle = 'Flutter Dashboard';

class RepositoryDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kTitle,
      home: const _RepositoryDashboardWidget(),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        '/settings': (BuildContext context) => const SettingsPage()
      },
      theme: ThemeData.dark(),
    );
  }
}

class _RepositoryDashboardWidget extends StatefulWidget {
  const _RepositoryDashboardWidget();
  @override
  _RepositoryDashboardWidgetState createState() =>
      _RepositoryDashboardWidgetState();
}

class _RepositoryDashboardWidgetState extends State<_RepositoryDashboardWidget>
    with SingleTickerProviderStateMixin {
  List<_RepositoryTabMapper> get _dashboardTabs {
    const double tabIconSize = 36.0;
    final RepositoryDetails flutterRepositoryDetails =
        const RepositoryDetails<FlutterRepositoryStatus>(
      icon: FlutterLogo(),
    );
    final RepositoryDetails engineRepositoryDetails =
        const RepositoryDetails<FlutterEngineRepositoryStatus>(
      icon: Icon(Icons.layers),
    );
    final RepositoryDetails pluginsRepositoryDetails =
        const RepositoryDetails<FlutterPluginsRepositoryStatus>(
      icon: Icon(Icons.extension),
    );
    return <_RepositoryTabMapper>[
      _RepositoryTabMapper(
          tab: const Tab(text: 'Flutter', icon: FlutterLogo(size: tabIconSize)),
          tabContents: flutterRepositoryDetails),
      _RepositoryTabMapper(
        tab: const Tab(
            text: 'Engine', icon: Icon(Icons.layers, size: tabIconSize)),
        tabContents: ModelBinding<FlutterEngineRepositoryStatus>(
          initialModel: FlutterEngineRepositoryStatus(),
          child: engineRepositoryDetails,
        ),
      ),
      _RepositoryTabMapper(
        tab: const Tab(
            text: 'Plugins', icon: Icon(Icons.extension, size: tabIconSize)),
        tabContents: ModelBinding<FlutterPluginsRepositoryStatus>(
            initialModel: FlutterPluginsRepositoryStatus(),
            child: pluginsRepositoryDetails),
      ),
      const _RepositoryTabMapper(
          tab: Tab(
              text: 'Infrastructure',
              icon: Icon(Icons.build, size: tabIconSize)),
          tabContents: const InfrastructureDetails()),
      const _RepositoryTabMapper(
          tab: Tab(
              text: 'Roll History',
              icon: Icon(Icons.merge_type, size: tabIconSize)),
          tabContents: const RollDetails()),
    ];
  }

  TabController _tabController;
  Timer _changeTabsTimer;

  /// This dashboard is made to be displayed on a TV.
  /// Refresh this page every day to pick up new versions so no one needs to get on a ladder and pair a keyboard to the TV.
  Timer _reloadPageTimer;

  @override
  void initState() {
    super.initState();
    _changeTabsTimer = Timer.periodic(const Duration(minutes: 1), _changeTabs);
    _reloadPageTimer = Timer.periodic(const Duration(days: 1), _reloadPage);
    final int tabCount = _dashboardTabs.length;

    int pausedTabIndex = tab.pausedTabIndex ?? 0;
    pausedTabIndex = math.min<int>(pausedTabIndex, tabCount - 1);
    _tabController = TabController(
        initialIndex: pausedTabIndex, vsync: this, length: tabCount);
    _tabController.addListener(_storeTabSelection);
  }

  @override
  void dispose() {
    _changeTabsTimer.cancel();
    _reloadPageTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _changeTabs(Timer timer) {
    if (tab.isPaused) return;

    int nextIndex = _tabController.index + 1;
    if (nextIndex > _dashboardTabs.length - 1) {
      nextIndex = 0;
    }
    _tabController.animateTo(nextIndex);
  }

  /// Handle user manually changing tabs while paused.
  void _storeTabSelection() {
    if (!tab.isPaused) return;
    tab.pausedTabIndex = _tabController.index;
  }

  void _reloadPage(Timer timer) {
    window.location.reload();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle currentHeadline = Theme.of(context).textTheme.headline;
    TextStyle headline = currentHeadline.copyWith(fontWeight: FontWeight.bold);
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: (tab.isPaused ? const Icon(Icons.play_arrow) : const Icon(Icons.pause)),
            tooltip: (tab.isPaused ? 'Switch tabs' : 'Stop switching tabs'),
            onPressed: () {
              setState(() {
                bool isPaused = !tab.isPaused;
                if (isPaused) {
                  tab.pause(_tabController.index);
                } else {
                  tab.play();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => window.location.href = '/'),
        bottom: TabBar(
            controller: _tabController,
            labelStyle:
                Theme.of(context).textTheme.body2.apply(fontSizeFactor: 1.6),
            indicatorWeight: 4.0,
            tabs: <Tab>[
              for (_RepositoryTabMapper tabMapper in _dashboardTabs)
                tabMapper.tab
            ]),
      ),
      body: Theme(
        data: ThemeData(
            textTheme: Theme.of(context).textTheme.copyWith(
                  body1: currentHeadline,
                  subhead: headline.copyWith(fontWeight: FontWeight.normal),
                  headline: headline,
                ),
            dividerColor: Theme.of(context).accentColor,
            iconTheme: IconTheme.of(context).copyWith(size: 30.0)),
        child: ListTileTheme(
          contentPadding: const EdgeInsets.only(bottom: 46.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 40.0, horizontal: 50.0),

            // The RepositoryDetails widgets are dependent on data fetched from the flutter/flutter FlutterRepositoryStatus repository.
            // Rebuild all widgets when that model changes.
            child: ModelBinding<FlutterRepositoryStatus>(
              initialModel: FlutterRepositoryStatus(),
              child: TabBarView(controller: _tabController, children: <Widget>[
                for (_RepositoryTabMapper tabMapper in _dashboardTabs)
                  tabMapper.tabContents
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryTabMapper {
  const _RepositoryTabMapper({@required this.tab, @required this.tabContents});
  final Tab tab;
  final Widget tabContents;
}
