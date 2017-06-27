// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart';

import 'package:cocoon_agent/src/agent.dart';
import 'package:cocoon_agent/src/commands/ci.dart';
import 'package:cocoon_agent/src/commands/run.dart';
import 'package:cocoon_agent/src/utils.dart';
import 'package:meta/meta.dart';

Future<Null> main(List<String> rawArgs) async {
  ArgParser argParser = new ArgParser()
    ..addOption(
      'config-file',
      abbr: 'c',
      defaultsTo: 'config.yaml'
    );
  argParser.addCommand('ci');
  argParser.addCommand('run', RunCommand.argParser);

  ArgResults args = argParser.parse(rawArgs);

  Config.initialize(args);

  Agent agent = new Agent(
    baseCocoonUrl: config.baseCocoonUrl,
    agentId: config.agentId,
    httpClient: new AuthenticatedClient(config.agentId, config.authToken)
  );

  Map<String, Command> allCommands = <String, Command>{};

  void registerCommand(Command command) {
    allCommands[command.name] = command;
  }

  registerCommand(new ContinuousIntegrationCommand(agent));
  registerCommand(new RunCommand(agent));

  if (args.command == null) {
    print('No command specified, expected one of: ${allCommands.keys.join(', ')}');
    exit(1);
  }

  Command command = allCommands[args.command.name];

  if (command == null) {
    print('Unrecognized command $command');
    exit(1);
  }

  section('Agent configuration:');
  print(config);

  await command.run(args.command);
}

/// An error thrown by [AuthenticatedClient].

class AuthenticatedClientError extends Error {
  AuthenticatedClientError({
    @required this.uri,
    @required this.statusCode,
    @required this.body,
  });

  final Uri uri;
  final int statusCode;
  final String body;

  @override
  String toString() => '$AuthenticatedClientError:\n'
      '  URI: $uri\n'
      '  HTTP status: $statusCode\n'
      '  Response body:\n'
      '$body';
}

class AuthenticatedClient extends BaseClient {
  AuthenticatedClient(this._agentId, this._authToken);

  final String _agentId;
  final String _authToken;
  final Client _delegate = new Client();

  @override
  Future<StreamedResponse> send(Request request) async {
    request.headers['Agent-ID'] = _agentId;
    request.headers['Agent-Auth-Token'] = _authToken;
    final StreamedResponse resp = await _delegate.send(request);

    if (resp.statusCode != 200) {
      throw new AuthenticatedClientError(
        uri: request.url,
        statusCode: resp.statusCode,
        body: (await Response.fromStream(resp)).body,
      );
    }

    return resp;
  }
}
