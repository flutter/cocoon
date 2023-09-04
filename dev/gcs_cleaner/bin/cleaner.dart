// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:gcloud/storage.dart';
import 'package:gcs_cleaner/cleaner.dart';
import 'package:gcs_cleaner/git.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:process/process.dart';

final ArgParser parser = ArgParser()
  ..addFlag(
    'dryrun',
    help: 'By default, this will list the artifacts that will be deleted.\n'
        'Passing --no-dryrun will delete the artifacts from GCS',
  )
  ..addOption(
    'engine',
    help: 'Path to the local engine checkout',
  )
  ..addOption(
    'framework',
    help: 'Path to a local framework checkout',
  )
  ..addOption(
    'token',
    help: 'GCS access token',
  )
  ..addOption(
    'ttl',
    help: 'Duration in days for age of artifacts that should be retained',
  );

Future<void> main(List<String> args) async {
  final flags = parser.parse(args);

  final Git frameworkGit = Git(
    path: flags['framework'],
    pm: const LocalProcessManager(),
  );
  final Git engineGit = Git(
    path: flags['engine'],
    pm: const LocalProcessManager(),
  );

  // Read the service account credentials from the file.
  final client = clientViaApiKey(flags['token']);
  final gcs = Storage(client, 'flutter-infra');
  // Default retention is 1 year.
  final ttl = Duration(days: int.tryParse(flags['ttl']) ?? 365);
  final Cleaner cleaner = Cleaner(
    fs: const LocalFileSystem(),
    gcs: gcs,
    engineGit: engineGit,
    frameworkGit: frameworkGit,
    isDryrun: flags['dryrun'],
    ttl: ttl,
  );

  await cleaner.clean();
}
