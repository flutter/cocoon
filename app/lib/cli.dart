// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:angular2/core.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

/// Command-line interface for Cocoon.
class Cli {
  static const commandTypes = const <Type>[
    CreateAgentCommand,
    AuthorizeAgentCommand,
    RefreshGithubCommitsCommand,
  ];

  factory Cli(Injector injector) {
    ArgParser argParser = new ArgParser();
    Map<String, CliCommand> commandMap = <String, CliCommand>{};

    print('Available CLI commands:');
    for (Type commandType in commandTypes) {
      CliCommand command = injector.get(commandType);

      if (command == null)
        throw 'Failed to register ${commandType}';

      commandMap[command.name] = command;
      print('  ${command.name}');
      argParser.addCommand(command.name, command.argParser);
    }

    return new Cli._(argParser, commandMap);
  }

  Cli._(this._argParser, this._commands);

  final ArgParser _argParser;
  final Map<String, CliCommand> _commands;

  Future<Null> run(List<String> rawArgs) async {
    ArgResults args = _argParser.parse(rawArgs);
    CliCommand command = _commands[args.command.name];

    if (command == null)
      throw 'Command ${args.name} not found';

    print('Running...');
    await command.run(args.command);
    print('Done.');
  }
}

abstract class CliCommand {
  CliCommand(this.name);

  /// Command name as it appears in the CLI.
  final name;

  ArgParser get argParser;

  Future<Null> run(ArgResults args);
}

@Injectable()
class AuthorizeAgentCommand extends CliCommand {
  AuthorizeAgentCommand(this.httpClient) : super('auth-agent');

  final http.Client httpClient;

  @override
  ArgParser get argParser {
    return new ArgParser()
      ..addOption(
        'agent-id',
        abbr: 'a',
        help: 'Unique agent ID.'
      );
  }

  @override
  Future<Null> run(ArgResults args) async {
    String agentId = args['agent-id'];
    http.Response resp = await httpClient.post('/api/authorize-agent', body: JSON.encode({
      'AgentID': agentId
    }));
    print(resp.body);
  }
}

@Injectable()
class CreateAgentCommand extends CliCommand {
  CreateAgentCommand(this.httpClient) : super('create-agent');

  final http.Client httpClient;

  @override
  ArgParser get argParser {
    return new ArgParser()
      ..addOption(
        'agent-id',
        abbr: 'a',
        help: 'Unique agent ID.'
      )
      ..addOption(
        'capability',
        abbr: 'c',
        allowMultiple: true,
        splitCommas: true,
        help: 'An agent capability. May be repeated to supply multiple capabilities.'
      );
  }

  @override
  Future<Null> run(ArgResults args) async {
    String agentId = args['agent-id'];
    List<String> capabilities = args['capability'];
    http.Response resp = await httpClient.post('/api/create-agent', body: JSON.encode({
      'AgentID': agentId,
      'Capabilities': capabilities,
    }));
    print(resp.body);
  }
}

@Injectable()
class RefreshGithubCommitsCommand extends CliCommand {
  RefreshGithubCommitsCommand(this.httpClient) : super('refresh-github-commits');

  final http.Client httpClient;

  @override
  ArgParser get argParser => new ArgParser();

  @override
  Future<Null> run(ArgResults args) async {
    http.Response resp = await httpClient.post('/api/refresh-github-commits');
    print(resp.body);
  }
}
