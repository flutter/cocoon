// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:codesign/codesign.dart';
import 'package:platform/platform.dart';

/// Definitions of variables are included in help texts below.
const String helpFlag = 'help';
const String kCommit = 'commit';
const String kProduction = 'production';
const String kCodesignCertName = 'codesign-cert-name';
const String kCodesignUserName = 'codesign-username';
const String kAppSpecificPassword = 'app-specific-password';
const String kCodesignAppStoreId = 'codesign-appstore-id';
const String kCodesignTeamId = 'codesign-team-id';
const String kCodesignFilepath = 'filepath';

/// Perform Mac code signing based on file paths.
///
/// If `--production` is set to true, code signed artifacts will be uploaded
/// back to google cloud storage.
/// Otherwise, nothing will be uploaded back for production. default value is
/// false.
///
/// For `--commit`, asks for the engine commit to be code signed.
///
/// For `--filepath`, provides the artifacts zip paths to be code signed.
///
/// Usage:
/// dart run bin/main.dart --commit=$commitSha
/// --filepath=darwin-x64/FlutterMacOS.framework.zip --filepath=ios/artifacts.zip
/// --filepath=dart-sdk-darwin-arm64.zip
/// ( add `--production` if this is intended for production)
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addFlag(helpFlag, help: 'Prints usage info.', callback: (bool value) {
      if (value) {
        stdout.write('${parser.usage}\n');
        exit(1);
      }
    })
    ..addOption(
      kCodesignCertName,
      help: 'The name of the codesign certificate to be used when codesigning.',
    )
    ..addOption(
      kAppSpecificPassword,
      help: 'Unique password specifically for codesigning the given application.',
    )
    ..addOption(
      kCodesignAppStoreId,
      help: 'Apple developer account email used for authentication with notary service.',
    )
    ..addOption(
      kCodesignTeamId,
      help: 'Team-id is used by notary service for xcode version 13+.',
    )
    ..addOption(
      kCommit,
      help: 'the commit hash of flutter/engine github pr used for google cloud storage bucket indexing',
    )
    ..addMultiOption(
      kCodesignFilepath,
      help: 'The zip file paths to be codesigned. Pass this option multiple'
          'times to codesign multiple zip files',
      valueHelp: 'darwin-x64/font-subset.zip',
    )
    ..addFlag(
      kProduction,
      help: 'whether we are going to upload the artifacts back to GCS for production',
    );

  final ArgResults argResults = parser.parse(args);

  final Platform platform = LocalPlatform();

  final String commit = getValueFromEnvOrArgs(kCommit, argResults, platform.environment)!;
  final String codesignCertName = getValueFromEnvOrArgs(kCodesignCertName, argResults, platform.environment)!;
  final String codesignUserName = getValueFromEnvOrArgs(kCodesignUserName, argResults, platform.environment)!;
  final String appSpecificPassword = getValueFromEnvOrArgs(kAppSpecificPassword, argResults, platform.environment)!;
  final String codesignAppstoreId = getValueFromEnvOrArgs(kCodesignAppStoreId, argResults, platform.environment)!;
  final String codesignTeamId = getValueFromEnvOrArgs(kCodesignTeamId, argResults, platform.environment)!;

  final List<String> codesignFilepaths = argResults[kCodesignFilepath]!;
  final bool production = argResults[kProduction] as bool;

  if (!platform.isMacOS) {
    throw ConductorException(
      'Error! Expected operating system "macos", actual operating system is: '
      '"${platform.operatingSystem}"',
    );
  }

  return CodesignContext(
    codesignCertName: codesignCertName,
    codesignUserName: codesignUserName,
    commitHash: commit,
    appSpecificPassword: appSpecificPassword,
    codesignAppstoreId: codesignAppstoreId,
    codesignTeamId: codesignTeamId,
    codesignFilepaths: codesignFilepaths,
    production: production,
  ).run();
}
