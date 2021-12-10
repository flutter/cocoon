// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/conductor.dart';
import 'services/dev_local_conductor.dart';
import 'services/local_conductor.dart';
import 'state/status_state.dart';
import 'widgets/clean_release_button.dart';
import 'widgets/progression.dart';

const String _title = 'Flutter Desktop Conductor';

Future<void> main() async {
  // The app currently only supports macOS and Linux.
  if (kIsWeb || io.Platform.isWindows) {
    throw Exception('The conductor only supports desktop on MacOS and Linux');
  }

  // TODO(unassigned): [release_dashboard] make isDev a List arg,
  // https://github.com/flutter/flutter/issues/95051.
  const bool isDev = true;

  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(
    isDev == true ? DevLocalConductorService() : LocalConductorService(),
    isDev: isDev,
  ));
}

/// Root app of the release dashboard.
///
/// [conductor] is the conductor service currently used.
///
/// When [isDev] is true, the app is in development mode, else, it is in production
/// mode. The release dashboard is in development mode by default.
class MyApp extends StatelessWidget {
  const MyApp(
    this.conductor, {
    this.isDev = true,
    Key? key,
  }) : super(key: key);

  final ConductorService conductor;
  final bool isDev;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StatusState(conductor: conductor),
      child: MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: const Text(_title),
            actions: const [
              CleanReleaseButton(),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  'Desktop app for managing a release of the Flutter SDK, currently in '
                  '${isDev == true ? 'dev' : 'prod'} mode (mode can be changed in main.dart).',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const SizedBox(height: 10.0),
                SelectableText(
                  'Please follow each step and substep in order.',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const SizedBox(height: 10.0),
                MainProgression(conductor: conductor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
