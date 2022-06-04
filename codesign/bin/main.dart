// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:codesign/codesign.dart';
import 'package:platform/platform.dart';

const String filepathFlag = 'filepath';
const String helpFlag = 'help';


const String kCommit = 'commit';
const String kVerify = 'verify';
const String kProduction = 'production';
const String kSignatures = 'signatures';
const String kRevision = 'revision';
const String kUpstream = 'upstream';
const String kCodesignCertName = 'codesign-cert-name';
const String kCodesignPrimaryBundleId = 'codesign-primary-bundle-id';
const String kCodesignUserName = 'codesign-username';
const String kAppSpecificPassword = 'app-specific-password';
const String kCodesignAppStoreId = 'codesign-appstore-id';
const String kCodesignTeamId = 'codesign-team-id';
const String kCodesignFilepath = 'filepath';

/// Perform mac code signing based on file path.
///
/// If `--production` is set to true, code signed artifacts will be uploaded back to google cloud storage.
/// Otherwise, nothing will be uploaded back for production.
///
/// For `--commit`, asks for the engine commit to be code signed.
///
/// For `--filepath`, provide the artifacts zip paths to be code signed.
///
/// Usage:
/// dart run bin/main.dart --commit=a5967ed309ef2beb9625f128571f7060597b5eda 
/// --production=false --filepath=darwin-x64/FlutterMacOS.framework.zip#ios/artifacts.zip#dart-sdk-darwin-arm64.zip 
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addFlag(helpFlag, help: 'Prints usage info.', callback: (bool value) {
      if (value) {
        stdout.write('${parser.usage}\n');
        exit(1);
      }
    })
    ..addFlag(
      kVerify,
      help:
          'Only verify expected binaries exist and are codesigned with entitlements.',
    )
    ..addFlag(
      kSignatures,
      defaultsTo: true,
      help:
          'When off, this command will only verify the existence of binaries, and not their\n'
          'signatures or entitlements. Must be used with --verify flag.',
    )
    ..addOption(
      kCodesignCertName,
      help: 'The name of the codesign certificate to be used when codesigning.',
    )
    ..addOption(
      kCodesignPrimaryBundleId,
      help: 'Identifier for the application you are codesigning. This is only used '
        'for disambiguating codesign jobs in the notary service logging.',
      defaultsTo: 'dev.flutter.sdk'
    )
    ..addOption(
      kCodesignUserName,
      help: 'Apple developer account email used for authentication with notary service.',
    )
    ..addOption(
      kAppSpecificPassword,
      help: 'Unique password specifically for codesigning the given application.',
    )
    ..addOption(
      kCodesignAppStoreId,
      help: 'Apple-id for connecting to app store. Used by notary service for xcode version 13+.',
    )
    ..addOption(
      kCodesignTeamId,
      help: 'Team-id is used by notary service for xcode version 13+.',
    )
    ..addOption(
      kCodesignFilepath,
      help: 'the # deliminated zip file paths to be codesigned. e.g. darwin-x64/font-subset.zip#darwin-x64-release/gen_snapshot.zip',
    )
    ..addOption(
      kCommit, 
      help: 'the commit hash of flutter/engine github pr used for google cloud storage bucket indexing')
    ..addOption(
      kProduction, 
      help: 'whether we are going to upload the artifacts back to GCS for production');
    


  final ArgResults argResults = parser.parse(args);

  final Platform platform = LocalPlatform();

  final String commit= getValueFromEnvOrArgs(kCommit, argResults, platform.environment)!;
  final String codesignCertName = getValueFromEnvOrArgs(kCodesignCertName, argResults, platform.environment)!;
  final String codesignPrimaryBundleId = getValueFromEnvOrArgs(kCodesignPrimaryBundleId, argResults, platform.environment)!;
  final String codesignUserName = getValueFromEnvOrArgs(kCodesignUserName, argResults, platform.environment)!;
  final String appSpecificPassword = getValueFromEnvOrArgs(kAppSpecificPassword, argResults, platform.environment)!;
  final String codesignAppstoreId = getValueFromEnvOrArgs(kCodesignAppStoreId, argResults, platform.environment)!;
  final String codesignTeamId = getValueFromEnvOrArgs(kCodesignTeamId, argResults, platform.environment)!;
  final String codesignFilepath = getValueFromEnvOrArgs(kCodesignFilepath, argResults, platform.environment)!;
  final bool production = getValueFromEnvOrArgs(kProduction, argResults, platform.environment)! == "true";

  if (!platform.isMacOS) {
    throw ConductorException(
      'Error! Expected operating system "macos", actual operating system is: '
      '"${platform.operatingSystem}"',
    );
  }

  return CodesignContext(
    codesignCertName: codesignCertName,
    codesignPrimaryBundleId: codesignPrimaryBundleId,
    codesignUserName: codesignUserName,
    commitHash: commit,
    appSpecificPassword: appSpecificPassword,
    codesignAppstoreId: codesignAppstoreId,
    codesignTeamId: codesignTeamId,
    codesignFilepath: codesignFilepath,
    production: production
  ).run();

}



