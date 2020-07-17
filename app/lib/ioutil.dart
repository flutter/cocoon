// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

void rm(FileSystemEntity entity) {
  if (entity.existsSync()) entity.deleteSync();
}

/// Remove recursively.
void rrm(FileSystemEntity entity) {
  if (entity.existsSync()) entity.deleteSync(recursive: true);
}

List<FileSystemEntity> ls(Directory directory) => directory.listSync();

Directory dir(String path) => new Directory(path);

File file(String path) => new File(path);

void copy(File sourceFile, Directory targetDirectory, {String name}) {
  File target = file(path.join(targetDirectory.path, name ?? path.basename(sourceFile.path)));
  target.writeAsBytesSync(sourceFile.readAsBytesSync());
}

FileSystemEntity move(FileSystemEntity whatToMove, {Directory to, String name}) {
  return whatToMove.renameSync(path.join(to.path, name ?? path.basename(whatToMove.path)));
}

/// Equivalent of `mkdir directory`.
void mkdir(Directory directory) {
  directory.createSync();
}

/// Equivalent of `mkdir -p directory`.
void mkdirs(Directory directory) {
  directory.createSync(recursive: true);
}

bool exists(FileSystemEntity entity) => entity.existsSync();

void section(String title) {
  print('');
  print('••• $title •••');
}

Future<Process> startProcess(String executable, List<String> arguments,
    {Map<String, String> env, Future<Null> onKill}) async {
  Process proc = await Process.start(executable, arguments, environment: env, workingDirectory: cwd);

  if (onKill != null) {
    bool processExited = false;

    // ignore: unawaited_futures
    proc.exitCode.then((_) {
      processExited = true;
    });

    // ignore: unawaited_futures
    onKill.then((_) {
      if (!processExited) {
        print('Caught signal to kill process (PID: ${proc.pid}): $executable ${arguments.join(' ')}');
        bool killed = proc.kill(ProcessSignal.sigkill);
        print('Process ${killed ? "was killed successfully" : "could not be killed"}.');
      }
    });
  }

  return proc;
}

Future<dynamic> inDirectory(dynamic directory, Future<dynamic> action()) async {
  String previousCwd = cwd;
  try {
    cd(directory);
    return await action();
  } finally {
    cd(previousCwd);
  }
}

void cd(dynamic directory) {
  Directory d;
  if (directory is String) {
    cwd = directory;
    d = dir(directory);
  } else if (directory is Directory) {
    cwd = directory.path;
    d = directory;
  } else {
    throw 'Unsupported type ${directory.runtimeType} of $directory';
  }

  if (!d.existsSync()) throw 'Cannot cd into directory that does not exist: $directory';
}
