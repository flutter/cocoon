// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:wait_for_tests/wait_for_tests.dart';

/// Runs the wait-for-tests tool to poll the Cocoon API until the requested pre-submit tests finish.
///
/// This CLI can be executed by passing options as command-line arguments:
/// ```sh
/// dart bin/wait_for_tests.dart --sha d100ca3882520e04129ff2a5c09372ecec3b3860 --repo flutter/flutter --required-tests "Linux windows_host_engine, Mac mac_ios_engine" --wait-interval 45
/// ```
/// Alternatively, it can read from environment variables (e.g., prefixed with `INPUT_` for GitHub Actions).
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'sha',
      abbr: 's',
      help: 'The full 40-character commit SHA to poll',
    )
    ..addOption(
      'repo',
      abbr: 'r',
      help:
          'The repository slug or name (e.g., flutter/flutter or flutter/packages)',
    )
    ..addMultiOption(
      'required-tests',
      abbr: 't',
      help:
          'Comma, newline, or repeatedly specified list of tests to wait for. If omitted, polls and waits for all scheduled tests.',
    )
    ..addOption(
      'wait-interval',
      abbr: 'i',
      defaultsTo: '60',
      help:
          'Time in seconds between polling checks (clamped to a range of 30 to 600 seconds)',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    );

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Error parsing arguments: $e');
    _printUsage(parser);
    exit(1);
  }

  if (argResults['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  // Support reading from environment variables for GitHub Actions
  final sha = argResults['sha'] as String? ?? Platform.environment['INPUT_SHA'];
  final repo =
      argResults['repo'] as String? ?? Platform.environment['INPUT_REPO'];

  final rawRequiredTestsList =
      argResults['required-tests'] as List<String>? ?? [];
  final envRequiredTests =
      Platform.environment['INPUT_REQUIRED_TESTS'] ??
      Platform.environment['INPUT_REQUIRED-TESTS'];

  final waitIntervalStr =
      argResults['wait-interval'] as String? ??
      Platform.environment['INPUT_WAIT_INTERVAL'] ??
      Platform.environment['INPUT_WAIT-INTERVAL'] ??
      '60';

  if (sha == null || sha.isEmpty) {
    stderr.writeln(
      'Error: The commit "sha" parameter is required (either via CLI argument or INPUT_SHA environment variable).',
    );
    _printUsage(parser);
    exit(1);
  }

  final shaRegex = RegExp(r'^[a-fA-F0-9]{40}$');
  if (!shaRegex.hasMatch(sha)) {
    stderr.writeln(
      'Error: The commit "sha" parameter must be a full 40-character hexadecimal SHA. Got: "$sha"',
    );
    exit(1);
  }

  if (repo == null || repo.isEmpty) {
    stderr.writeln(
      'Error: The "repo" parameter is required (either via CLI argument or INPUT_REPO environment variable).',
    );
    _printUsage(parser);
    exit(1);
  }

  final RepositorySlug slug;
  try {
    final parts = repo.split('/');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw const FormatException();
    }
    slug = RepositorySlug(parts[0], parts[1]);
  } catch (_) {
    stderr.writeln(
      'Error: Malformed "repo" parameter. Expected format "owner/repo" (e.g., "flutter/cocoon"), but got: "$repo"',
    );
    exit(1);
  }

  final List<String> requiredTests;
  if (rawRequiredTestsList.isNotEmpty) {
    requiredTests = rawRequiredTestsList
        .expand((s) => s.split(RegExp(r'[,\n]')))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  } else if (envRequiredTests != null && envRequiredTests.isNotEmpty) {
    requiredTests = envRequiredTests
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  } else {
    requiredTests = const [];
  }

  final waitIntervalSeconds = int.tryParse(waitIntervalStr);
  if (waitIntervalSeconds == null) {
    stderr.writeln(
      'Error: "wait-interval" must be a valid integer. Got: $waitIntervalStr',
    );
    exit(1);
  }

  final waitInterval = Duration(seconds: waitIntervalSeconds);

  final client = http.Client();
  try {
    final success = await waitForTests(
      sha: sha,
      slug: slug,
      requiredTests: requiredTests,
      waitInterval: waitInterval,
      client: client,
      log: stdout.writeln,
    );

    if (success) {
      stdout.writeln('Success: Action completed successfully!');
      exit(0);
    } else {
      stderr.writeln('Failure: Action completed with errors.');
      exit(1);
    }
  } catch (e, stackTrace) {
    stderr.writeln('Error: An unexpected error occurred: $e');
    stderr.writeln(stackTrace);
    exit(1);
  } finally {
    client.close();
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: wait-for-tests [options]\n');
  stdout.writeln(
    'This command-line tool can be configured either via command-line arguments',
  );
  stdout.writeln(
    'or environment variables (e.g., prefixed with INPUT_ for GitHub Actions).\n',
  );
  stdout.writeln(parser.usage);
}
