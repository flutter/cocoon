// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:js';

import 'package:angular2/core.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

/// Command-line interface for Cocoon.
class Cli {
  static const commandTypes = const <Type>[
    CreateAgentCommand,
    AuthorizeAgentCommand,
    RefreshGithubCommitsCommand,
    ReserveTaskCommand,
    RawHttpCommand,
  ];

  /// Installs global JS object `cocoon` callable from Chrome's dev tools.
  ///
  /// Usage:
  ///
  /// cocoon.method([...COMMAND_ARGS]);
  ///
  /// See `cliCommands` for list of available commands.
  static void install(Injector injector) {
    Map<String, Function> commandMap = <String, Function>{};

    print('Available CLI commands:');
    for (Type commandType in commandTypes) {
      CliCommand command = injector.get(commandType);

      if (command == null)
        throw 'Failed to register ${commandType}';

      print('  ${command.name}');
      commandMap[command.name] = (List<String> args) {
        command.run(command.argParser.parse(args));
        return 'Running...';
      };
    }

    context['cocoon'] = new JsObject.jsify(commandMap);
  }
}

abstract class CliCommand {
  CliCommand(this.name);

  /// Command name as it appears in the CLI.
  final String name;

  ArgParser get argParser;

  Future<Null> run(ArgResults args);
}

@Injectable()
class AuthorizeAgentCommand extends CliCommand {
  AuthorizeAgentCommand(this.httpClient) : super('authAgent');

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
    http.Response resp = await httpClient.post('/api/authorize-agent', body: json.encode({
      'AgentID': agentId
    }));
    print(resp.body);
  }
}

@Injectable()
class CreateAgentCommand extends CliCommand {
  CreateAgentCommand(this.httpClient) : super('createAgent');

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
    http.Response resp = await httpClient.post('/api/create-agent', body: json.encode({
      'AgentID': agentId,
      'Capabilities': capabilities,
    }));
    print(resp.body);
  }
}

@Injectable()
class RefreshGithubCommitsCommand extends CliCommand {
  RefreshGithubCommitsCommand(this.httpClient) : super('refreshGithubCommits');

  final http.Client httpClient;

  @override
  ArgParser get argParser => new ArgParser();

  @override
  Future<Null> run(ArgResults args) async {
    http.Response resp = await httpClient.post('/api/refresh-github-commits');
    print(resp.body);
  }
}

@Injectable()
class ReserveTaskCommand extends CliCommand {
  ReserveTaskCommand(this.httpClient) : super('reserveTask');

  final http.Client httpClient;

  @override
  ArgParser get argParser {
    return new ArgParser()
      ..addOption(
        'agent-id',
        abbr: 'a',
        help: 'Identifies the agent to reserve a task for.'
      );
  }

  @override
  Future<Null> run(ArgResults args) async {
    String agentId = args['agent-id'];
    http.Response resp = await httpClient.post('/api/reserve-task', body: json.encode({
      'AgentID': agentId
    }));
    print(resp.body);
  }
}

@Injectable()
class RawHttpCommand extends CliCommand {
  RawHttpCommand(this.httpClient) : super('http');

  final http.Client httpClient;

  @override
  ArgParser get argParser {
    return new ArgParser();
  }

  @override
  Future<Null> run(ArgResults args) async {
    String method = args.rest[0];
    String path = args.rest[1];
    String body = args.rest.length > 2 ? args.rest[2] : null;

    http.Response resp;
    if (method.toLowerCase() == 'get') {
      resp = await httpClient.get(path);
    } else if (method.toLowerCase() == 'post') {
      resp = await httpClient.post(path, body: body);
    }
    print(resp.body);
  }
}
