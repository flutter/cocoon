// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:process/process.dart';

enum FILETYPE {
  FOLDER, ZIP, BINARY, OTHER
}

/// Check mime-type of file at [filePath] to determine if it is binary.
bool isBinary(String filePath, ProcessManager processManager) {
  final ProcessResult result = processManager.runSync(
    <String>[
      'file',
      '--mime-type',
      '-b', // is binary
      filePath,
    ],
  );
  return (result.stdout as String).contains('application/x-mach-binary');
}

/// Check mime-type of file at [filePath] to determine if it is a directory.
FILETYPE checkFileType(String filePath, ProcessManager processManager) {
  final ProcessResult result = processManager.runSync(
    <String>[
      'file',
      '--mime-type',
      '-b', // is binary
      filePath,
    ],
  );
  String output = result.stdout as String;
  if(output.contains('inode/directory')){
    return FILETYPE.FOLDER;
  }else if(output.contains('application/zip')){
    return FILETYPE.ZIP;
  }else if(output.contains('application/x-mach-binary')){
    return FILETYPE.BINARY;
  }else{
    return FILETYPE.OTHER;
  }
}

List<String> listFiles(String filePath, ProcessManager processManager) {
  final ProcessResult result = processManager.runSync(
    <String>[
      'ls',
      '-1',
      filePath,
    ],
  );
  return (result.stdout as String).split('\n').where((String s) => s.isNotEmpty).toList();
}

Future<bool> isSymlink(String fileOrFolderPath, ProcessManager processManager) async {
  final ProcessResult result = processManager.runSync(
    <String>[
      'ls',
      '-alhf',
      fileOrFolderPath,
    ],
  );
  
  return (result.stdout as String).split('\n').where((String s) => !s.split(' ').contains('->') &&
  s.trim().isNotEmpty).isEmpty;
}