// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:cocoon_code_health/src/checks.dart';
import 'package:cocoon_code_health/src/checks/do_not_submit_fixme.dart';
import 'package:cocoon_code_health/src/checks/no_trailing_spaces.dart';
import 'package:cocoon_code_health/src/checks/use_test_logging.dart';
import 'package:cocoon_common/cocoon_common.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;

final _parser = ArgParser(allowTrailingOptions: false)
  ..addOption(
    'repository-root',
    help: 'The root of the flutter/cocoon repository.',
    defaultsTo: _findRepositoryRoot(),
  )
  ..addFlag('quiet', abbr: 'q', help: 'Quiet output')
  ..addFlag('verbose', abbr: 'v', help: 'Show additional output');

const _anyPackageChecks = [DoNotSubmitFixme(), NoTrailingWhitespace()];
const _serverPackageChecks = [..._anyPackageChecks, UseTestLogging()];

final _checks = {
  p.join('analyze'): _anyPackageChecks,
  p.join('app_dart'): _serverPackageChecks,
  p.join('cipd_packages', 'codesign'): _anyPackageChecks,
  p.join('cipd_packages', 'device_doctor'): _anyPackageChecks,
  p.join('cipd_packages', 'doxygen'): _anyPackageChecks,
  p.join('cipd_packages', 'ktlint'): _anyPackageChecks,
  p.join('cipd_packages', 'ruby'): _anyPackageChecks,
  p.join('cloud_build'): _anyPackageChecks,
  p.join('dashboard'): _anyPackageChecks,
  p.join('dev', 'githubanalysis'): _anyPackageChecks,
  p.join('licenses'): _anyPackageChecks,
  p.join('licenses'): _anyPackageChecks,
  p.join('packages', 'buildbucket-dart'): _anyPackageChecks,
  p.join('packages', 'cocoon_common'): _anyPackageChecks,
  p.join('packages', 'cocoon_common_test'): _anyPackageChecks,
  p.join('packages', 'cocoon_server'): _anyPackageChecks,
  p.join('packages', 'cocoon_server_test'): _anyPackageChecks,
  p.join('test_utilities'): _anyPackageChecks,
  p.join('tooling'): _anyPackageChecks,
};

void main(List<String> args) async {
  final parsed = _parser.parse(args);
  final cocoon = parsed.option('repository-root');
  if (cocoon == null) {
    io.stderr.writeln('Could not find the repository root');
    io.exitCode = 1;
    return;
  }

  final verbose = parsed.flag('verbose');
  final quiet = parsed.flag('quiet') && !verbose;
  const fs = LocalFileSystem();

  for (final MapEntry(key: package, value: checks) in _checks.entries) {
    for (final check in checks) {
      if (!quiet) {
        io.stderr.writeln('Running ${check.runtimeType} on $package...');
      }

      // Look at tracked files using git ls-files.
      final gitLsFiles = io.Process.runSync('git', ['-C', package, 'ls-files']);
      if (gitLsFiles.exitCode != 0) {
        io.stderr.writeln(gitLsFiles.stderr);
        io.exitCode = 1;
        return;
      }
      final trackedFiles = (gitLsFiles.stdout as String)
          .split('\n')
          .map((p) => fs.file(fs.path.join(package, p)));
      for (final file in trackedFiles) {
        if (!check.include.any((g) => g.matches(file.path))) {
          continue;
        }
        // Exclude the directory (package) itself.
        if (file.path == package) {
          continue;
        }
        final relative = p.relative(file.path, from: cocoon);
        if (check.exclude.any((g) => g.matches(relative))) {
          if (verbose) {
            io.stderr.writeln('${check.runtimeType} $relative: Skip');
          }
          continue;
        }
        final logger = BufferedLogger();
        final result = await check.check(logger, file);
        if (result == CheckResult.failed) {
          io.exitCode = 1;
          for (final message in logger.messages) {
            io.stderr.writeln(
              '${message.severity.name}: ${check.runtimeType}\n'
              '$relative\n'
              '${message.message}\n',
            );
          }
        } else if (verbose) {
          io.stderr.writeln('${check.runtimeType} $relative: Pass');
        }
      }
    }
  }

  io.stderr.writeln('Done!');
}

String? _findRepositoryRoot() {
  var current = io.Directory.current;
  while (true) {
    final pubspec = io.File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final contents = pubspec.readAsStringSync();
      if (contents.contains('name: _cocoon_workspace')) {
        return current.path;
      }
    }
    if (p.equals(current.path, current.parent.path)) {
      return null;
    }
    current = current.parent;
  }
}
