// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cocoon_server/google_auth_provider.dart';
import 'package:cocoon_service/src/request_handlers/get_presubmit_guard.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:github/github.dart';
import 'package:googleapis_auth/auth_io.dart' as g;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class AccessTokenAuthProvider implements GoogleAuthProvider {
  final String accessToken;
  const AccessTokenAuthProvider(this.accessToken);

  @override
  Future<http.Client> createClient({
    required List<String> scopes,
    http.Client? baseClient,
  }) async {
    return g.authenticatedClient(
      baseClient ?? http.Client(),
      g.AccessCredentials(
        g.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        scopes,
      ),
    );
  }
}

class ApplicationDefaultAuthProvider implements GoogleAuthProvider {
  const ApplicationDefaultAuthProvider();

  @override
  Future<http.Client> createClient({
    required List<String> scopes,
    http.Client? baseClient,
  }) {
    return g.clientViaApplicationDefaultCredentials(
      scopes: scopes,
      baseClient: baseClient,
    );
  }
}

void main(List<String> args) async {
  // Initialize logging to output directly to the terminal.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.message}');
    if (record.error != null) {
      print('[ERROR] ${record.error}');
    }
  });

  final parser = ArgParser()
    ..addOption('sha', abbr: 's', mandatory: true, help: 'Commit SHA to query')
    ..addOption(
      'slug',
      abbr: 'r',
      defaultsTo: 'flutter/packages',
      help: 'Repository slug',
    )
    ..addFlag('help', abbr: 'h');

  final ArgResults parsedArgs;
  try {
    parsedArgs = parser.parse(args);
  } catch (e) {
    print('Error parsing arguments: $e');
    print(parser.usage);
    exit(1);
  }

  if (parsedArgs.wasParsed('help')) {
    print(r'''
Usage example:
  ACCESS_TOKEN="$(gcloud auth application-default print-access-token)" \
  dart bin/get_presubmit_guard_cli.dart \
    --slug fltuter/packages \
    --sha GIT_SHA
    ''');
    print(parser.usage);
    return;
  }

  final sha = parsedArgs['sha'] as String;
  final slug = RepositorySlug.full(parsedArgs['slug'] as String);

  print(
    'Querying presubmit guard status for $slug @ $sha using shared GetPresubmitGuard...',
  );

  final accessToken = Platform.environment['ACCESS_TOKEN'];
  final GoogleAuthProvider authProvider;
  if (accessToken != null && accessToken.isNotEmpty) {
    authProvider = AccessTokenAuthProvider(accessToken);
  } else {
    authProvider = const ApplicationDefaultAuthProvider();
  }

  final firestore = await FirestoreService.from(authProvider);

  try {
    final handler = GetPresubmitGuard(
      config: CliConfig(),
      firestore: firestore,
    );

    final requestUri = Uri.parse(
      'http://localhost/api/public/get-presubmit-guard?owner=${slug.owner}&repo=${slug.name}&sha=$sha',
    );
    final response = await handler.get(CliRequest(requestUri));

    if (response.statusCode != HttpStatus.ok) {
      print(
        '\n[FAILURE] No records found in Firestore for slug $slug and sha $sha (status: ${response.statusCode}).',
      );
      print(
        'This commit may not be tracked yet or has not been ingested by Cocoon.',
      );
      exit(1);
    }

    final bodyBytes = [await for (final body in response.body) ...body];
    final bodyString = utf8.decode(bodyBytes);
    final bodyJson = jsonDecode(bodyString) as Map<String, dynamic>;

    print('\n[SUCCESS] Presubmit Guard Response:');
    print(const JsonEncoder.withIndent('  ').convert(bodyJson));
  } catch (e, s) {
    print('\n[FAILURE] Error retrieving presubmit guard: $e');
    print(s);
    exit(1);
  }
}

class CliConfig implements Config {
  @override
  DynamicConfig get flags => DynamicConfig(enableGeminiLogAnalysis: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CliRequest implements Request {
  @override
  final Uri uri;

  @override
  final String method = 'GET';

  @override
  final RequestResponse response = CliRequestResponse();

  CliRequest(this.uri);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CliRequestResponse implements RequestResponse {
  @override
  int statusCode = 200;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
