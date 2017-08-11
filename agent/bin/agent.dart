// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';

import 'package:cocoon_agent/src/agent.dart';
import 'package:cocoon_agent/src/commands/ci.dart';
import 'package:cocoon_agent/src/commands/run.dart';
import 'package:cocoon_agent/src/utils.dart';

/// Agents periodically poll the server for more tasks. This sleep period is
/// used to prevent us from DDoS-ing the server.
const Duration _sleepBetweenBuilds = const Duration(seconds: 10);

/// Extra amount of time we give the command isolate to finish before
/// forcefully quitting it.
const Duration _kGracePeriod = const Duration(minutes: 2);

/// The amount of time we give the command isolate to request a task and
/// report the desired task timeout, before we give up.
/// 
/// This generally does not take a lot of time - connect to App Engine, reserve
/// a task, parse task data, report timeout.
const Duration _kTimeoutTimeout = const Duration(minutes: 1);

final List<StreamSubscription> _streamSubscriptions = <StreamSubscription>[];

Future<Null> main(List<String> rawArgs) async {
  _listenToShutdownSignals();

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

  Map<String, Command> allCommands = <String, Command>{};

  void registerCommand(Command command) {
    allCommands[command.name] = command;
  }

  registerCommand(new ContinuousIntegrationCommand());
  registerCommand(new RunCommand());

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

  await new IsolateCommandRunner().run(command, args.command);
}

/// Runs commands in an isolate.
class IsolateCommandRunner {
  Future<Null> run(Command command, ArgResults commandArgs) async {
    Completer commandCompleter = new Completer();
    Completer<Duration> targetTimeout = new Completer<Duration>();

    ReceivePort messagePort = new ReceivePort()..listen((dynamic message) {
      if (message is Duration)
        targetTimeout.complete(message);
      else
        throw new Exception('Unsupported message from command isolate of type ${message.runtimeType}: $message');
    });

    ReceivePort exitPort = new ReceivePort()..listen((_) {
      commandCompleter.complete();
    });

    ReceivePort errorPort = new ReceivePort()..listen((List<String> errorInfo) {
      String stackTrace = errorInfo[1];
      commandCompleter.completeError(
        errorInfo[0],
        stackTrace != null ? new StackTrace.fromString(stackTrace) : null,
      );
    });

    Isolate isolate = await Isolate.spawn(
      _runCommandInIsolate,
      new CommandConfig(config, command, commandArgs, messagePort.sendPort),
      errorsAreFatal: false,
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
    );

    try {
      Duration timeout = await targetTimeout.future.timeout(_kTimeoutTimeout);

      Timer timeoutTimer = new Timer(timeout + _kGracePeriod, () {
        if (!commandCompleter.isCompleted)
          commandCompleter.completeError(new TimeoutException('Command isolate took too long to finish.'));
      });

      await commandCompleter.future;
      timeoutTimer.cancel();
    } catch (error, stackTrace) {
      print('Error in command isolate: $error');
      print(stackTrace);
      print('\nKilling isolate as might be in inconsistent state.');
      isolate.kill();
      if (!command.runContinuously) {
        print('Quitting with error');
        exit(1);
      }
    } finally {
      if (command.runContinuously) {
        print('Pause before the next cycle.');
        await new Future.delayed(_sleepBetweenBuilds);
        await run(command, commandArgs);
      }
    }
  }
}

void _runCommandInIsolate(CommandConfig commandConfig) {
  Config.adopt(commandConfig.config);
  commandConfig.command.run(commandConfig.args, commandConfig.sendPort);
}

void _listenToShutdownSignals() {
  _streamSubscriptions.add(
    ProcessSignal.SIGINT.watch().listen((_) {
      print('\nReceived SIGINT. Shutting down.');
      _stop();
    })
  );
  if (!Platform.isWindows) {
    _streamSubscriptions.add(
      ProcessSignal.SIGTERM.watch().listen((_) {
        print('\nReceived SIGTERM. Shutting down.');
        _stop();
      })
    );
  }
}

Future<Null> _stop() async {
  print('Stopping');

  for (StreamSubscription sub in _streamSubscriptions) {
    await sub.cancel();
  }
  _streamSubscriptions.clear();

  exit(0);
}

class CommandConfig {
  CommandConfig(this.config, this.command, this.args, this.sendPort);

  final Config config;
  final Command command;
  final ArgResults args;
  final SendPort sendPort;
}
