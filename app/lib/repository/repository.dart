// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web/material.dart';

import 'details/repository.dart';
import 'details/roll.dart';
import 'details/settings.dart';
import 'models/providers.dart';
import 'models/repository_status.dart';
import 'models/roll_history.dart';

const String kTitle = 'Flutter Dashboard';

class RepositoryDashboardApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kTitle,
      home: ModelBinding<FlutterRepositoryStatus>(
        initialModel: FlutterRepositoryStatus(),
        child: ModelBinding<FlutterEngineRepositoryStatus>(
          initialModel: FlutterEngineRepositoryStatus(),
          child: ModelBinding<FlutterPluginsRepositoryStatus>(
            initialModel: FlutterPluginsRepositoryStatus(),
            child: ModelBinding<FlutterWebsiteRepositoryStatus>(
              initialModel: FlutterWebsiteRepositoryStatus(),
              child: ModelBinding<FlutterPackagesRepositoryStatus>(
                  initialModel: FlutterPackagesRepositoryStatus(),
                  child: ModelBinding<RollHistory>(
                      initialModel: RollHistory(),
                      child: _RepositoryDashboardWidget()
                  )
              ),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder> {
        '/settings': (BuildContext context) => const SettingsPage()
      },
      theme: ThemeData.dark(),
    );
  }
}

class _RepositoryDashboardWidget extends StatelessWidget {
  const _RepositoryDashboardWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: Theme(
          data: ThemeData.light(),
          child: GridView.extent(
            padding: const EdgeInsets.all(10.0),
            maxCrossAxisExtent: 450.0,
            childAspectRatio: .55,
            children: <Widget>[
              RepositoryDetails<FlutterRepositoryStatus>(
                  icon: FlutterLogo(),
                  labelEvaluation: (labelName) => (labelName == 'waiting for tree to go green' || labelName == '⚠ TODAY' || labelName.startsWith('severe: customer'))
              ),
              RepositoryDetails<FlutterPluginsRepositoryStatus>(
                  icon: Icon(Icons.extension),
                  labelEvaluation: (labelName) => labelName.startsWith('p:')
              ),
              RepositoryDetails<FlutterEngineRepositoryStatus>(
                  icon: Icon(Icons.layers),
                  labelEvaluation: (labelName) => (labelName == 'engine' || labelName.startsWith('e:'))
              ),
              RepositoryDetails<FlutterPackagesRepositoryStatus>(
                  icon: Icon(Icons.unarchive),
                  labelEvaluation: (labelName) => (labelName == 'package')
              ),
              RepositoryDetails<FlutterWebsiteRepositoryStatus>(
                  icon: Icon(Icons.web),
                  labelEvaluation: (labelName) => labelName.startsWith('d: website')
              ),
              RollDetails()
            ],
          )
      ),
    );
  }
}
