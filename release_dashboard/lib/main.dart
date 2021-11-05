// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services/conductor.dart';
import 'services/local_conductor.dart';
import 'widgets/common/dialog_prompt.dart';
import 'package:provider/provider.dart';

import 'state/status_state.dart';
import 'widgets/progression.dart';

const String _title = 'Flutter Desktop Conductor (Not ready, do not use)';

Future<void> main() async {
  // The app currently only supports macOS and Linux.
  if (kIsWeb || io.Platform.isWindows) {
    throw Exception('The conductor only supports desktop on MacOS and Linux');
  }

  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(LocalConductorService()));
}

class MyApp extends StatelessWidget {
  const MyApp(
    this.conductor, {
    Key? key,
  }) : super(key: key);

  final ConductorService conductor;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StatusState(conductor: conductor),
      child: MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: const Text(_title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SelectableText(
                  'Desktop app for managing a release of the Flutter SDK, currently in development',
                ),
                const SizedBox(height: 10.0),
                MainProgression(
                  releaseState: conductor.state,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button to clean the current release.
class CleanRelease extends StatelessWidget {
  const CleanRelease({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 40, 0),
      child: IconButton(
        key: const Key('conductorClean'),
        icon: const Icon(Icons.delete),
        onPressed: () {
          dialogPrompt(
            context: context,
            title: 'Are you sure you want to clean up the current release?',
            content: 'This will abort and delete a work in progress release. This process is not revertible!',
            leftOptionTitle: 'Yes',
            rightOptionTitle: 'No',
          );
        },
        tooltip: 'Clean up the current release.',
      ),
    );
  }
}
