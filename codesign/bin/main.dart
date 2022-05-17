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

/// Binaries that are expected to be codesigned and have entitlements.
List<String> binariesWithEntitlements = <String>[
    'artifacts/engine/android-arm-profile/darwin-x64/gen_snapshot',
    'artifacts/engine/android-arm-release/darwin-x64/gen_snapshot',
    'artifacts/engine/android-arm64-profile/darwin-x64/gen_snapshot',
    'artifacts/engine/android-arm64-release/darwin-x64/gen_snapshot',
    'artifacts/engine/android-x64-profile/darwin-x64/gen_snapshot',
    'artifacts/engine/android-x64-release/darwin-x64/gen_snapshot',
    'artifacts/engine/darwin-x64-profile/gen_snapshot',
    'artifacts/engine/darwin-x64-profile/gen_snapshot_arm64',
    'artifacts/engine/darwin-x64-profile/gen_snapshot_x64',
    'artifacts/engine/darwin-x64-release/gen_snapshot',
    'artifacts/engine/darwin-x64-release/gen_snapshot_arm64',
    'artifacts/engine/darwin-x64-release/gen_snapshot_x64',
    'artifacts/engine/darwin-x64/flutter_tester',
    'artifacts/engine/darwin-x64/gen_snapshot',
    'artifacts/engine/darwin-x64/impellerc',
    'artifacts/engine/darwin-x64/libtessellator.dylib',
    'artifacts/engine/darwin-x64/gen_snapshot_arm64',
    'artifacts/engine/darwin-x64/gen_snapshot_x64',
    'artifacts/engine/ios-profile/gen_snapshot_arm64',
    'artifacts/engine/ios-release/gen_snapshot_arm64',
    'artifacts/engine/ios/gen_snapshot_arm64',
    'artifacts/libimobiledevice/idevicescreenshot',
    'artifacts/libimobiledevice/idevicesyslog',
    'artifacts/libimobiledevice/libimobiledevice-1.0.6.dylib',
    'artifacts/libplist/libplist-2.0.3.dylib',
    'artifacts/openssl/libcrypto.1.1.dylib',
    'artifacts/openssl/libssl.1.1.dylib',
    'artifacts/usbmuxd/iproxy',
    'artifacts/usbmuxd/libusbmuxd-2.0.6.dylib',
    'dart-sdk/bin/dart',
    'dart-sdk/bin/dartaotruntime',
    'dart-sdk/bin/utils/gen_snapshot',
  ];

/// Binaries that are only expected to be codesigned.
List<String> binariesWithoutEntitlements = [
    'artifacts/engine/darwin-x64-profile/FlutterMacOS.framework/Versions/A/FlutterMacOS',
    'artifacts/engine/darwin-x64-release/FlutterMacOS.framework/Versions/A/FlutterMacOS',
    'artifacts/engine/darwin-x64/FlutterMacOS.framework/Versions/A/FlutterMacOS',
    'artifacts/engine/darwin-x64/font-subset',
    'artifacts/engine/darwin-x64/impellerc',
    'artifacts/engine/darwin-x64/libtessellator.dylib',
    'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/engine/ios/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/ios-deploy/ios-deploy',
  ];

/// Perform mac code signing based on file path.
///
/// For `healthcheck`, if no device is found or any health check fails an stderr will be logged,
/// and an exception will be thrown.
///
/// For `recovery`, it will do cleanup, reboot, etc. to try bringing device back to a working state.
///
/// For `prepare`, it will prepare the device before running tasks, like kill running processes, etc.
///
/// For `properties`, it will return device properties/dimensions, like manufacture, base_buildid, etc.
///
/// Usage:
/// dart main.dart --action <healthcheck|recovery> --deviceOS <android|ios>
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
    // ..addOption(
    //   kUpstream,
    //   defaultsTo: FrameworkRepository.defaultUpstream,
    //   help: "The git remote URL to use as the Flutter framework's upstream.",
    // )
    ..addFlag(
      kSignatures,
      defaultsTo: true,
      help:
          'When off, this command will only verify the existence of binaries, and not their\n'
          'signatures or entitlements. Must be used with --verify flag.',
    )
    // ..addOption(
    //   kRevision,
    //   help: 'The Flutter framework revision to use.',
    // )
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
      help: 'the commit hash of flutter/engine github pr used for google cloud storage bucket indexing');
    


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

  if (!platform.isMacOS) {
    throw ConductorException(
      'Error! Expected operating system "macos", actual operating system is: '
      '"${platform.operatingSystem}"',
    );
  }

  return CodesignContext(
    binariesWithEntitlements: binariesWithEntitlements,
    binariesWithoutEntitlements: binariesWithoutEntitlements,
    codesignCertName: codesignCertName,
    codesignPrimaryBundleId: codesignPrimaryBundleId,
    codesignUserName: codesignUserName,
    commitHash: commit,
    appSpecificPassword: appSpecificPassword,
    codesignAppstoreId: codesignAppstoreId,
    codesignTeamId: codesignTeamId,
    codesignFilepath: codesignFilepath,
  ).run();

}



