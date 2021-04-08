// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:cocoon_service/cocoon_service.dart';

class Repo {
  const Repo({
    @required this.name,
    @required this.remoteUrl,
    this.ref = 'master',
  });

  final String name;

  /// Remote URL to clone from.
  final String remoteUrl;

  /// Default git ref to checkout.
  final String ref;
}

/// List of repositories that have valid .ci.yaml config files.
const List<Repo> allRepos = <Repo>[
  Repo(
    name: 'framework',
    remoteUrl: 'https://github.com/flutter/flutter.git',
  ),
];

void main() {
  const FileSystem fs = LocalFileSystem();

  for (final Repo repo in allRepos) {
    test('validate config file of ${repo.name}', () {
      final Directory dir = fs.systemTempDirectory.createTempSync(repo.name);

      final io.ProcessResult result = io.Process.runSync(
        'git',
        <String>['clone', '-b', repo.ref, '--', repo.remoteUrl, dir.path],
      );
      expect(
        result.exitCode,
        0,
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );

      final File configFile = dir.childFile('.ci.yaml');
      final YamlMap configYaml = loadYaml(configFile.readAsStringSync()) as YamlMap;
      try {
        loadSchedulerConfig(configYaml);
      } on FormatException catch (e) {
        fail(e.message);
      }
    });
  }
}
