// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'src/settings/settings.dart';
import 'src/app.dart';
import 'src/models.dart';
import 'src/providers.dart';
import 'src/service.dart';

final clientId = '308150028417-7rl94q5rmnamqavdlnnke4lee8h7htje.apps.googleusercontent.com';
final clientSecret = 'kjZjhPq9oAycS6iZdrAqBZJQ';

final googleSignIn = GoogleSignIn(
  scopes: <String>[],
);

void main() {
  runApp(const Entrypoint());
}

class Entrypoint extends StatefulWidget {
  const Entrypoint();

  @override
  _EntrypointState createState() {
    return _EntrypointState();
  }
}

class _EntrypointState extends State<Entrypoint> {
  ApplicationService service;
  BuildBrokenModel buildBrokenModel;
  BuildStatusModel buildStatusModel;
  UserSettingsModel userSettingsModel;
  BenchmarkModel benchmarkModel;
  SignInModel signInModel;
  ClockModel clockModel;
  CommitModel commitModel;
  MementoRegistry registry;

  @override
  void initState() {
    service = ApplicationService();
    buildBrokenModel = BuildBrokenModel(service: service);
    buildStatusModel = BuildStatusModel(service: service);
    userSettingsModel = UserSettingsModel();
    benchmarkModel = BenchmarkModel(userSettingsModel: userSettingsModel, service: service);
    signInModel = SignInModel(service: service, googleSignIn: googleSignIn);
    clockModel = ClockModel();
    commitModel = CommitModel(signInModel: signInModel, service: service);
    registry = MementoRegistry([
      benchmarkModel,
      buildStatusModel,
      commitModel,
    ]);
    registry.init();
    signInModel.checkGithubStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = ThemeData(
      primarySwatch: Colors.blueGrey,
      fontFamily: 'OpenSans',
    );
    var app = MaterialApp(
      title: 'Flutter Dashboard',
      theme: theme,
      home: const MetapodApp(),
      debugShowCheckedModeBanner: false,
      routes: {
        'settings': (BuildContext context) => const SettingsPage(),
      },
    );
    return ApplicationProvider(
      buildBrokenModel: buildBrokenModel,
      buildStatusModel: buildStatusModel,
      userSettingsModel: userSettingsModel,
      benchmarkModel: benchmarkModel,
      signInModel: signInModel,
      clockModel: clockModel,
      commitModel: commitModel,
      child: app,
    );
  }
}
