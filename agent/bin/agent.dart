// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:cocoon_agent/src/agent.dart';
import 'package:cocoon_agent/src/commands/ci.dart';
import 'package:cocoon_agent/src/commands/run.dart';
import 'package:cocoon_agent/src/utils.dart';

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

  Agent agent;
  try {
    agent = new Agent(
      baseCocoonUrl: config.baseCocoonUrl,
      agentId: config.agentId,
      authToken: config.authToken,
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
    config.toString()
      .split('\n')
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .forEach(logger.info);

    await command.run(args.command);
  } finally {
    if (agent != null) {
      agent.close();
    }
  }
}
