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

const String _title = 'Flutter Desktop Conductor (Not ready, do not use)';

Future<void> main() async {
  // The app currently only supports macOS and Linux.
  if (kIsWeb || io.Platform.isWindows) {
    throw Exception('The conductor only supports desktop on MacOS and Linux');
  }

  const bool isDev = true;

  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(isDev == true ? DevLocalConductorService() : LocalConductorService()));
}

class MyApp extends StatefulWidget {
  const MyApp(
    this.conductor, {
    Key? key,
  }) : super(key: key);

  final ConductorService conductor;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _force = false;

  void setForce(bool value) {
    setState(() {
      _force = value;
    });
    widget.conductor.force = value;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StatusState(conductor: widget.conductor),
      child: MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: const Text(_title),
            actions: [
              Row(children: [
                Text('Force push if ${_force == true ? 'on' : 'off'}'),
                Switch(
                  key: const Key('forceSwitch'),
                  value: _force,
                  onChanged: (bool value) {
                    setForce(value);
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                ),
              ]),
              const SizedBox(width: 20.0),
              const CleanReleaseButton(),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  'Desktop app for managing a release of the Flutter SDK, currently in development',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const SizedBox(height: 10.0),
                SelectableText(
                  'Please follow each step and substep in order.',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const SizedBox(height: 10.0),
                MainProgression(conductor: widget.conductor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
