import 'dart:io';

import 'package:auto_submit/git/cli_command.dart';

class FakeCliCommand extends CliCommand {
  FakeCliCommand();

  late ProcessResult processResult;
  late ProcessException processException;
  late bool throwException;

  @override
  Future<ProcessResult> runCliCommand({
    required String executable,
    required List<String> arguments,
    bool throwOnError = true,
    String? workingDirectory,
  }) async {
    if (throwException) {
      throw processException;
    }

    return processResult;
  }
}
