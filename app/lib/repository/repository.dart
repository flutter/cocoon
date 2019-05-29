// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

import 'package:flutter_web/material.dart';

import 'details/infrastructure.dart';
import 'details/repository.dart';
import 'details/roll.dart';
import 'details/settings.dart';
import 'models/providers.dart';
import 'models/repository_status.dart';

const String kTitle = 'Flutter Dashboard';

class RepositoryDashboardApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kTitle,
      home: const _RepositoryDashboardWidget(),
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
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => window.location.href = '/'
        ),
      ),
      body: Theme(
        data: ThemeData.light(),

        // The RepositoryDetails widgets are dependent on data fetched from the flutter/flutter FlutterRepositoryStatus repository. Rebuild all grid widgets when that model changes.
        child: ModelBinding<FlutterRepositoryStatus>(
          initialModel: FlutterRepositoryStatus(),
          child: GridView.extent(
            padding: const EdgeInsets.all(10.0),
            maxCrossAxisExtent: 450.0,
            childAspectRatio: .55,
            children: <Widget>[
              RepositoryDetails<FlutterRepositoryStatus>(
                icon: const FlutterLogo(),
                labelEvaluation: (String labelName) => <String>[
                  'waiting for tree to go green',
                  '⚠ TODAY',
                  'severe: customer blocker',
                  'severe: customer critical',
                  'framework',
                  'f: cupertino',
                  'f: material design',
                  'tool',
                  'will need additional triage',
                  'customer: crowd',
                ].contains(labelName)
              ),
              ModelBinding<FlutterEngineRepositoryStatus>(
                initialModel: FlutterEngineRepositoryStatus(),
                child: RepositoryDetails<FlutterEngineRepositoryStatus>(
                  icon: Icon(Icons.layers),
                  labelEvaluation: (String labelName) => labelName == 'engine'
                    || labelName == 'needs love'
                    || labelName.startsWith('e:')
                    || labelName.startsWith('affects:')
                ),
              ),
              ModelBinding<FlutterPluginsRepositoryStatus>(
                initialModel: FlutterPluginsRepositoryStatus(),
                child: RepositoryDetails<FlutterPluginsRepositoryStatus>(
                  icon: Icon(Icons.extension),
                  labelEvaluation: (String labelName) => labelName.startsWith('p:')
                    || labelName == 'flutterfire'
                    || labelName == 'needs love'
                ),
              ),
              const InfrastructureDetails(),
              const RollDetails()
            ],
            addAutomaticKeepAlives: true,
          )
        ),
      ),
    );
  }
}
